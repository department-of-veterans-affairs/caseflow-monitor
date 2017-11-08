class SampleController < ApplicationController

  attr_accessor :results

  def index
    get_data
    respond_to do |format|
      format.json { render(json: @results.as_json ) }
    end
  end

  def services
    get_data
      services_results = @results.values.each_with_object([]) do |element, boolean_result|
        if element[:up_rate_5].to_i < 50
          boolean_result << { element[:name] => :false }
        else
          boolean_result << { element[:name] => :true }
        end
      end
    respond_to do |format|
      format.json { render(json: services_results.as_json ) }
    end
  end

  def get_data
    @results = {}

    Rails.application.config.monitor_services.each do |service|
      datapoint = Rails.cache.read(service.service_name)

      if datapoint != nil
        @results[service.service_name.to_sym] = datapoint
      end
    end
    @results
  end
end
