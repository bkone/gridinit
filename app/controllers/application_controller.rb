class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?
  helper_method :admin_user?

  helper_method :generate_guid
  helper_method :hash_keys_to_sym

  helper_method :master_node

  # before_filter :authenticate if Rails.env.staging?

  before_filter :nodes

  protected

  def nodes
    @node             = Node.find_or_create_by_host(ENV['PUBLIC_IPV4']) if ENV['PUBLIC_IPV4'].size > 0
    @nodes            = Node.all
  end

  def master_node
    return true if Node.find_by_host_and_role(ENV['PUBLIC_IPV4'], 'master')
  end

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['BASIC_AUTH_USR'] && password == ENV['BASIC_AUTH_PWD']
    end
  end

  private

  def generate_guid
    UUIDTools::UUID.timestamp_create().to_s.gsub('-','')
  end

  def hash_keys_to_sym(hash)
    Hash[YAML.load(hash).map{ |k, v| [k.to_sym, v] }]
  end

  def current_user
    begin
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    rescue
      nil
    end
  end

  def user_signed_in?
    return true if current_user
  end
  
  def correct_user?
    @user = User.find(params[:id])
    unless current_user == @user
      redirect_to :back, :notice => 'Access is denied.'
    end
  end

  def admin_user?
    if current_user
      return true if current_user.role == 'admin'
    else
      false
    end
  end

  def require_admin!
    if Rails.env.production?
      if !current_user 
        redirect_to :back, :notice => 'Please sign in to use this functionality.'
      elsif current_user.role != 'admin'
        redirect_to :back, :notice => 'Your account is not authorized for administative functions.'
      end
    end
  end
  
  def authenticate_user!
    if Rails.env.production? or Rails.env.staging?
      if !current_user
        redirect_to :back, :notice => 'Please sign in to use this functionality.'
      end
    end
  end
end