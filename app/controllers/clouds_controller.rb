class CloudsController < ApplicationController

  def create
    enqueue(@node.host, :create_on_aws)
  end

  def destroy
    enqueue(@node.host, :destroy_on_aws)
  end

  private

  def enqueue(queue, action)
    Resque::Job.create(queue, CloudsController, action, params)
  end

  def self.perform(action, params)
    self.send(action.to_sym, params)
  end

  def self.create_on_aws(params)
    server = $fog.servers.create(
      :image_id   => 'ami-8a7f3ed8',
      :flavor_id  => 't1.micro',
      :key_name   => 'grid-node-ap-southeast'
    )
    server.wait_for { ready? }
    logger.debug server.dns_name
    logger.debug server
    node = Node.find_or_create_by_host(server.dns_name)
    node.instance_id = server
    node.user_id = @current_user.id
  end

  def self.destroy_on_aws(params)
    node = Node.find_by_host!(params[:id])
    server = $fog.servers.get(node.instance_id)
    server.destroy
  end 

end