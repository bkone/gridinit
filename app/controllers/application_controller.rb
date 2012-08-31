class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :authenticate_user!
  helper_method :authenticate_paying_user!
  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?
  helper_method :admin_user?
  helper_method :paying_user?
  helper_method :user_has_private_nodes?
  helper_method :generate_guid
  helper_method :hash_keys_to_sym
  helper_method :master_node

  before_filter :nodes
  before_filter :init
  
  protected

  def nodes
    @node    = ENV['PUBLIC_IPV4'].size > 0 ? Node.find_or_create_by_host(ENV['PUBLIC_IPV4']) : Node.first
    @nodes   = Node.find(:all,
      :conditions => ["user_id IN(?)",
      (user_signed_in? ? [0,current_user.id] : 0)])
  end

  def init
    if User.count == 0
      render 'dashboard/init'
    end
  end

  def master_node
    return true if Node.find_by_host_and_role(ENV['PUBLIC_IPV4'], 'master')
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
      redirect_to :back, :alert => 'Access is denied.'
    end
  end

  def admin_user?
    if current_user
      return true if current_user.role == 'admin'
    else
      false
    end
  end

  def paying_user?
    if current_user
      current_user.card_token ? true : false
    else
      false
    end
  end

  def user_has_private_nodes?
    if admin_user?
      true
    elsif current_user
      Node.count(:conditions =>  ["user_id =(?)", current_user.id]) > 0 ? true : false
    else
      false
    end
  end

  def require_admin!
    if !current_user 
      redirect_to :back, :alert => 'Please sign in to use this functionality.'
    elsif current_user.role != 'admin'
      redirect_to :back, :alert => 'Your account is not authorized for administative functions.'
    end
  end
  
  def authenticate_user!
    if !current_user
      redirect_to :back, :alert => 'Please sign in to use this functionality.'
    end
  end

  def authenticate_paying_user!
    authenticate_user!
    if !@current_user.card_token
      redirect_to :back, :alert => 'This feature is reserved for paid accounts only.'
    end
  end
end