class UsersController < ApplicationController
   before_filter :require_admin!

  def index
    @users   = User.find(:all)
    @users_paginated = Kaminari.paginate_array(@users).page(params[:users_page]).per(50)
    respond_to do |format|
      format.html
      format.json { render :json => @users.to_json }
    end
  end

end
