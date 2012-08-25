class SupportController < ApplicationController
  before_filter :authenticate_user!

  def create
    SupportMailer.send_feedback(params).deliver
    redirect_to '/dashboard'
  end
 
end