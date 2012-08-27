class HealthController < ApplicationController
  skip_before_filter :init
  
  def index
  	headers['Access-Control-Allow-Origin'] = "*"
    services = ['logstash', 'elasticsearch', 'resque', 'redis']
    if services.reject! {|s| `ps aux | grep #{s[0..-2]}[#{s[-1]}]` != '' }.size > 0
      render :json => { :errors => "#{services.to_sentence} are not running" }, :status => 500
    else
      render :json => { :message => "All services running" }
    end
  end
end