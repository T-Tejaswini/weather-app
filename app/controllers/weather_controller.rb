class WeatherController < ApplicationController
  # renders form to input address info
  def new
  end

  # renders weather information for given address
  def detail
    detail = ::Services::WeatherService.call(detail_params)
    @data = detail.dig(:data)
    @cache_info = detail.dig(:cache_info)
    @error = detail.dig(:message)
  end

  private

  def detail_params
    params.permit(:address)
  end
end
