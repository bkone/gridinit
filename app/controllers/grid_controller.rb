class GridController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :authenticate_paying_user!

  def create
    params[:user]     = (user_signed_in? ? current_user.id : 0)
    params[:quantity].to_i.times do |i| 
      node = Node.create!(
        :host        => 'node starting',
        :region      => params[:region],
        :location    => location_in_region(params[:region]),
        :user_id     => params[:user]
      )
      params[:node_id] = node.id
      enqueue(@node.host, :create_on_aws)
    end
    redirect_to :back, :notice => "#{pluralize params[:quantity], 'node'} started."
  end

  def destroy
    params[:user]     = (user_signed_in? ? current_user.id : 0)
    enqueue(@node.host, :destroy_on_aws)
  end

  private

  def location_in_region(region)
    case region
    when "au_nsw" 
      "Australia (Sydney)"
    when "us_east_1" 
      "US East (Northern Virginia)"
    when "us_west_1" 
      "US West (Oregon)"
    when "us_west-2" 
      "US West (Northern California)"
    when "eu_west_1" 
      "EU (Ireland)"
    when "ap_southeast_1"
      "Asia Pacific (Singapore)"
    when "ap_northeast_1" 
      "Asia Pacific (Tokyo)"
    when "sa_east_1"
      "South America (Sao Paulo)"
    end
  end

  def enqueue(queue, action)
    Resque::Job.create(queue, GridController, action, params)
  end

  def self.perform(action, params)
    params = Hash[params.map{ |k, v| [k.to_sym, v] }]
    self.send(action.to_sym, params)
  end

  def self.create_on_aws(params)
    server = $fog.servers.create(
      :image_id   => $image_ids[params[:region]],
      :flavor_id  => $flavor_id
      # :region     => params[:region]
    )
    server.wait_for { ready? }
    node = Node.find(params[:node_id])
    node.host        = server.public_ip_address
    node.instance_id = server.id
    if node.save
      transaction = Transaction.new do |t|
        t.instance_id   = node.instance_id
        t.instance_type = 'm1.large'
        t.user_id       = node.user_id
        t.node_id       = node.id
        t.stop_after    = params[:auto_stop] if params[:auto_stop]
      end
      transaction.save!
    end
  end

  def self.destroy_on_aws(params)
    server = $fog.servers.get(params[:instance_id])
    server.destroy if server
  end 
end