class DashboardController < ApplicationController
  before_filter :require_admin!, :except => [:index, :shared]
  
  def index
    @runs   = Run.find(:all,
      :conditions => ["privacy_flag IN(?) OR privacy_flag IS NULL",
      (user_signed_in? ? [0,current_user.id] : 0)])
    @runs_paginated = Kaminari.paginate_array(@runs.reverse).page(params[:runs_page]).per(5)
    @total_threads = Run.sum(:threads)    
    @total_hits = Elasticsearch.get_total_hits(params)
  end

  def shared
    @run = Run.find_by_id!(params[:id])
    @total_hits = Elasticsearch.get_total_hits(params)
    render 'dashboard/shared', :layout => false
  end
end