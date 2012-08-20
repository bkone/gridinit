class SupportMailer < ActionMailer::Base
  default :from => "support@gridinit.com"

  def send_feedback(params)
    mail(
      :from => params[:from],
      :to => 'support@gridinit.com', 
      :subject => params[:subject],
      :body => params[:body]
    )
  end
end