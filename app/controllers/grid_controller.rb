class GridController < ApplicationController
  before_filter :authenticate_paying_user!

  def create
    params[:user]     = (user_signed_in? ? current_user.id : 0)
    params[:quantity].to_i.times {|i| enqueue(@node.host, :create_on_aws) }
    redirect_to :back, :notice => "#{params[:quantity]} node(s) started."
  end

  def destroy
    params[:user]     = (user_signed_in? ? current_user.id : 0)
    enqueue(@node.host, :destroy_on_aws)
  end

  private

  def enqueue(queue, action)
    Resque::Job.create(queue, GridController, action, params)
  end

  def self.perform(action, params)
    params = Hash[params.map{ |k, v| [k.to_sym, v] }]
    self.send(action.to_sym, params)
  end

  def self.create_on_aws(params)
    server = $fog.servers.create(
      :image_id   => 'ami-8a7f3ed8',
      :flavor_id  => 'm1.large'
    )
    server.wait_for { ready? }
    node = Node.new do |n|
      n.host        = server.public_ip_address
      n.instance_id = server.id
      n.user_id     = params[:user]
    end
    if node.save
      transaction = Transaction.new do |t|
        t.instance_id   = node.instance_id
        t.instance_type = 'm1.large'
        t.user_id       = node.user_id
        t.node_id       = node.id
      end
      transaction.save!
    end
  end

  def self.destroy_on_aws(params)
    node = Node.find_by_host!(params[:id])
    server = $fog.servers.get(node.instance_id)
    server.destroy if server    
    transaction = Transaction.find_by_instance_id(node.instance_id)
    hours = ( (node.stopped - node.created_at).to_i / 3600 ).round
    transaction.hours = hours
    transaction.save!
  end 
end