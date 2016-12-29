class MonitorController < ApplicationController

  def admin
    @feedback = Monitor.all
  end

  def new
    puts "Rails cache #{Rails.cache.read('bgs')}"
  end

  def results
    results = {
      bgs: Rails.cache.read('bgs')
    }

    puts results[:bgs].inspect
    # puts results[:bgs]
    return results

  end

  helper_method :results
end
