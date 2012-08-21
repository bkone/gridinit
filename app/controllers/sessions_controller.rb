class SessionsController < ApplicationController
  skip_before_filter :init
  def create
    auth = request.env['omniauth.auth']
    case auth['provider']
    when 'github'
      user = User.where(:provider => auth['provider'], :uid => auth['uid']).first || User.create_with_omniauth(auth)
    when 'google'
      user = User.where(:provider => auth['provider'], :uid => auth['token']).first || User.create_with_omniauth(auth)
    when 'twitter'
      user = User.where(:provider => auth['provider'], :uid => auth['oauth_token']).first || User.create_with_omniauth(auth)
    when 'developer'
      user = User.where(:provider => auth['provider'], :uid => auth['uid']).first || User.create_with_omniauth(auth)
    end
    session[:user_id] = user.id
    redirect_to '/dashboard'
  end

  def new
    redirect_to "/auth/#{params[:provider]}"
  end

  def destroy
    reset_session
    redirect_to root_url
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end
end
