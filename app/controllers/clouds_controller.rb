class CloudsController < ApplicationController
  before_filter :require_admin!

  def create
    params[:user]     = (user_signed_in? ? current_user.id : 0)
    enqueue(@node.host, :create_on_aws)
  end

  def destroy
    params[:user]     = (user_signed_in? ? current_user.id : 0)
    enqueue(@node.host, :destroy_on_aws)
  end

  private

  def enqueue(queue, action)
    Resque::Job.create(queue, CloudsController, action, params)
  end

  def self.perform(action, params)
    params = Hash[params.map{ |k, v| [k.to_sym, v] }]
    self.send(action.to_sym, params)
  end

  def self.create_on_aws(params)
    server = $fog.servers.create(
      :image_id   => 'ami-8a7f3ed8',
      :flavor_id  => 't1.micro'
    )
    server.wait_for { ready? }
    node = Node.new do |n|
      n.host        = server.dns_name
      n.instance_id = server.id
      n.user_id     = params[:user]
    end
    node.save!
  end

  def self.destroy_on_aws(params)
    node = Node.find_by_host!(params[:id])
    server = $fog.servers.get(node.instance_id)
    server.destroy
  end 

end