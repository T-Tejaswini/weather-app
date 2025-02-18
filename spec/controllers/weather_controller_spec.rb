require 'rails_helper'

RSpec.describe WeatherController, :type => :controller do
  describe '#new' do
    before do
      get :new
    end

    it 'returns success' do
      expect(response).to be_successful
    end
  end

  describe '#detail' do
    context 'when weather service returns successful response' do
      before do
        allow(::Services::WeatherService).to receive(:call).and_return service_response
        get :detail
      end

      let(:service_response) do
        {
          status: 'success',
          data: [],
          cache_info: {}
        }
      end

      it 'returns success' do
        expect(response).to be_successful
      end
    end

    context 'when weather service raises an error' do
      before do
        allow_any_instance_of(::Services::WeatherService).to receive(:call).and_raise(StandardError, "error")
        get :detail
      end

      it 'returns success' do
        expect(response).to be_successful
      end
    end
  end
end
