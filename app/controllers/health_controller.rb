class HealthController < ApplicationController
  skip_before_filter :init
  
  def show
  	headers['Access-Control-Allow-Origin'] = "*"
    healthy = `ps aux | grep #{params[:id][0..-2]}[#{params[:id][-1]}]` != ''
    if healthy
      render :json => { :message => "#{params[:id]} running" }
    else
      render :json => { :errors => "#{params[:id]} not running" }, :status => 500
    end
  end
end