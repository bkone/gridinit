class DashboardController < ApplicationController
  before_filter :require_admin!, :except => [:index, :shortened, :shared]
  
  def index
    @runs   = Run.find(:all,
      :conditions => ["privacy_flag IN(?) OR privacy_flag IS NULL",
      (user_signed_in? ? [0,current_user.id] : 0)])
    @runs_paginated = Kaminari.paginate_array(@runs.reverse).page(params[:runs_page]).per(5)
    @total_threads = Run.sum(:threads)    
    @total_hits = Elasticsearch.get_total_hits(params)
  end

  def shortened
    @run = Run.find_by_id!(params[:id])
    params = hash_keys_to_sym @run.params
    redirect_to URI.escape "http://gridinit.com/shared?tags=#{params[:source]}&testguid=#{params[:testguid]}&domain=#{params[:domain]}&run_id=#{@run.id}"
  end

  def shared
    @run = Run.find_by_id!(params[:run_id])
    params = hash_keys_to_sym @run.params
    @total_hits = Elasticsearch.get_total_hits(params)
    render 'dashboard/shared', :layout => false
  end
end