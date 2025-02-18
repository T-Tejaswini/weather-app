require 'net/http'

module Services
  # Returns weather information given address as in input.
  class WeatherService
    attr_accessor :address, :units, :expires_in

    # Input - address
    #
    # Returns a hash with weather information
    def self.call(params)
      new(params).call
    rescue StandardError => e
      Rails.logger.error "Errored while making a request to fetch weather info: #{e}"
      { status: 'error', message: 'Error occured while retrieving data. Contact Customer service'}
    end

    def initialize(params)
      @address = params[:address]
      @expires_in = params[:expires_in] || 30.minutes
      @units = params.fetch(:units, 'imperial')
    end

    # returns weather information for given address.
    #
    # caches data for 30 mins(default) by zipcode
    def call
      return { status: 'failure', message: 'Address Not Found'} if location.blank?

      Rails.cache.fetch("weather_info_#{location.postal_code}", expires_in: expires_in) do
        response = Net::HTTP.get_response(uri)

        result = if response.code == '200'
                   data = parsed_response(response.body)

                   { status: 'success', data: data }
                 else
                   { status: 'failure', message: response.message }
                 end

        is_cached = Rails.application.config.action_controller.perform_caching

        result[:cache_info] = { cached_at: (is_cached ? Time.now : nil), is_cached: is_cached }
        result
      end
    end

    # Returns co-ordinates and postal code for given address string.
    def location
      @location ||= Geocoder.search(address).first
    end

    # Builds response structure for display
    #
    # Returns date and forecast info
    def parsed_response(body)
      parsed_data = JSON.parse(body)['list']

      parsed_data.map do |rec|
        {
          info: rec['main'],
          date_time: rec['dt_txt']
        }
      end
    end

    def query_attrs
      lat, lon = location.coordinates

      {
        lat: lat,
        lon: lon,
        units: units,
        appid: Rails.application.credentials[:openweather_app_id]
      }
    end

    def uri
      uri = URI(base_url)
      uri.query = URI.encode_www_form(query_attrs)
      uri
    end

    def base_url
      "https://api.openweathermap.org/data/2.5/forecast"
    end
  end
end
