require 'rails_helper'
require 'ostruct'

RSpec.describe Services::WeatherService do
  let(:subject) { ::Services::WeatherService.call(params) }

  let(:params) do
    { address: '123 speed' }
  end

  describe '#call' do
    let(:uri) do
      uri = URI('https://api.openweathermap.org/data/2.5/forecast')
      uri.query = URI.encode_www_form({
        lat: location.coordinates[0],
        lon: location.coordinates[1],
        units: 'imperial',
        appid: Rails.application.credentials[:openweather_app_id]
      })
      uri
    end

    let(:address) { params[:address] }

    context 'when geocoder returns no records for location search' do
      before do
        allow(Geocoder).to receive(:search).with(address).and_return []
      end

      it 'returns an error response' do
        expect(subject).to eq ({status: 'failure', message: 'Address Not Found'})
      end
    end

    context 'when geocoder returns a valid record' do
      let(:location) do
        double('Geocoder::Result::Nominatim', postal_code: '12312', coordinates: [56.7, 25.2])
      end

      before do
        allow(Geocoder).to receive(:search).with(address).and_return [location]
      end

      context 'when api returns failure response' do
        let(:api_response) do
          OpenStruct.new({
            code: '401',
            message: 'Unauthorized'
          })
        end

        it 'returns failure response' do
          expect(Net::HTTP).to receive(:get_response).with(uri).and_return api_response
          expect(subject).to eq ({
            cache_info: { cached_at: nil, is_cached: false },
            message: 'Unauthorized',
            status: 'failure'
          })
        end
      end

      context 'when api raised an error' do

        it 'returns failure response' do
          expect(Net::HTTP).to receive(:get_response).with(uri).and_raise(StandardError, "error")
          expect(subject).to eq ({
            message: 'Error occured while retrieving data. Contact Customer service',
            status: 'error'
          })
        end
      end

      context 'when api returns success response' do
        let(:api_response) do
          OpenStruct.new({
            code: '200',
            body: {
              'list' => [
                'main' => {
                  'temp' => 34.2,
                  'feels_like' => 30.2,
                  'temp_min' => 12.2,
                  'temp_max' => 59.2,
                  'pressure' => 1022,
                  'temp_kf' => 1.91,
                  'sea_level' => 1022
                },
                'dt_txt' => Date.today
              ]
            }.to_json
          })
        end

        it 'returns weather data' do
          expect(Net::HTTP).to receive(:get_response).with(uri).and_return api_response
          expect(subject).to eq ({
            cache_info: { cached_at: nil, is_cached: false },
            data: [
              {
                date_time: Date.today.strftime("%Y-%m-%d"),
                info: {
                  'feels_like'=>30.2,
                  'temp'=>34.2,
                  'temp_max'=>59.2,
                  'temp_min'=>12.2
                }
              }
            ],
            status: 'success'
          })
        end
      end
    end
  end
end
