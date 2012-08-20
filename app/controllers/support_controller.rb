class SupportController < ApplicationController
  def create
    SupportMailer.send_feedback(params).deliver
    redirect_to '/dashboard'
  end
 
end