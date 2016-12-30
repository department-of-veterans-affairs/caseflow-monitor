class MonitorController < ApplicationController

  def results

    results = {}
    bgs = Rails.cache.read('bgs')
    if bgs != nil
      results[:bgs] = bgs
    end

    vacols = Rails.cache.read('vacols')
    if vacols != nil
      results[:vacols] = vacols
    end

    vbms = Rails.cache.read('vbms')
    if vbms != nil
      results[:vbms] = vbms
    end

    return results

  end

  helper_method :results
end
