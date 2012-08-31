class HealthController < ApplicationController
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper
  skip_before_filter :init
  
  def index
  	headers['Access-Control-Allow-Origin'] = "*"
    services  = ['logstash', 'elasticsearch', 'resque', 'redis']
    duration  = Time.now - @node.created_at
    cost      = duration/60 * 0.06
    stats = {
      :started  => @node.created_at, 
      :duration => distance_of_time_in_words(duration),
      :cost     => number_to_currency(cost)
    }
    if services.reject! {|s| `ps aux | grep #{s[0..-2]}[#{s[-1]}]` != '' }.size > 0
      stats[:services] = "#{services.to_sentence.capitalize} are not running!"
      render :json => stats, :status => 500
    else
      stats[:services] = "All services are running."
      render :json => stats
    end
  end
end