class SampleController < ApplicationController
  def index

    results = {}
<<<<<<< Updated upstream
    puts "reading ...."
    Rails.application.config.monitor_services.each do |service|
      puts "reading from #{service.service_name}"
      datapoint = Rails.cache.read(service.service_name)
      puts datapoint
=======
    Rails.application.config.monitor_services.each do |service|
      datapoint = Rails.cache.read(service.service_name)
>>>>>>> Stashed changes
      if datapoint != nil
        results[service.service_name.to_sym] = datapoint
      end
    end
    respond_to do |format|
      format.json { render(json: results.as_json ) }
    end
  end
end
