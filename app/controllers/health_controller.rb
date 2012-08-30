class HealthController < ApplicationController
  skip_before_filter :init
  
  def index
  	headers['Access-Control-Allow-Origin'] = "*"
    services = ['logstash', 'elasticsearch', 'resque', 'redis']
    if services.reject! {|s| `ps aux | grep #{s[0..-2]}[#{s[-1]}]` != '' }.size > 0
      render :json => { 
        :health => "#{services.to_sentence} are not running", 
        :started => @node.created_at, 
        :stopped => @node.stopped }, :status => 500
    else
      render :json => { 
        :health => "All services running", 
        :started => @node.created_at, 
        :stopped => @node.stopped }
    end
  end
end