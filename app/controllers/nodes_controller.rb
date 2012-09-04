class NodesController < ApplicationController

  def index
    require_admin!
    @nodes   = Node.all
    @nodes_paginated = Kaminari.paginate_array(@nodes).page(params[:nodes_page]).per(10)
  end

  def slave
    require_admin!
    node = Node.new do |n|
      n.host        = params[:slave]
      n.user_id     = current_user.id
      n.role        = 'slave'
    end
    if node.save!
      redirect_to :back, :notice => "Slave node registered."
    else 
      redirect_to :back, :alert => 'Unable to register slave node.'
    end
  end
 
  def update
    node = Node.find_by_host!(params[:id])
    if permissions_on(node)
      node.update_attributes(
        :role => params[:role],
        :user_id => (params[:use] == 'public' ? 0 : current_user.id),
        :master => (params[:role] == 'slave' ? params[:master] : nil) )
      enqueue(node.host, :update_config)
      enqueue(node.host, :restart_services)
    end
    redirect_to :back
  end

  def destroy
    if params[:node_id]
      node = Node.find(params[:node_id])
    else
      node = Node.find_by_host!(params[:id])
    end
    if permissions_on(node)
      Node.destroy(node.id)
      transaction = Transaction.find_by_node_id(node.id)
      if transaction
        transaction.stopped_at = Time.now
        transaction.save!
        Resque::Job.create(@node.host, GridController, :destroy_on_aws, params)
      end
      redirect_to '/dashboard', :notice => 'Node was stopped.'
    else
      redirect_to :back, :alert => 'Access to this node is denied.'
    end
  end

  def enqueue(queue, action)
    Resque::Job.create(queue, NodesController, action, params)
  end

  def self.perform(action, params)
    params = Hash[params.map{ |k, v| [k.to_sym, v] }]
    self.send(action.to_sym, params)
  end

  private

  def permissions_on(node)
    case node.user_id
    when 0
      admin_user? ? true : false
    else
      current_user.id == node.user_id ? true : false
    end
  end

  def self.restart_services(params)
    self.restart_elasticsearch
    self.restart_redis
    self.restart_logstash
    self.restart_worker
    self.reapply_mappings
  end

  def self.update_config(params)
    node = Node.find_by_host!(params[:id])
    logstash = File.read("#{Rails.root}/config/logstash-#{node.role}").gsub('gridinit.com', params[:master] ? params[:master] : '127.0.0.1')
    File.open("#{Rails.root}/config/logstash.conf", 'w+'){|f| f << logstash } 
    
    redis = File.read("#{Rails.root}/config/redis.yml").gsub(/host:.+/, params[:master] ? "host: #{params[:master]}" : "host: localhost")
    File.open("#{Rails.root}/config/redis.yml", 'w+'){|f| f << redis } 
  end

  def self.restart_redis
    `sudo /etc/init.d/redis-server restart`
  end

  def self.restart_elasticsearch
    `sudo /etc/init.d/elasticsearch restart`
  end

  def self.restart_logstash
   `sudo /etc/init.d/logstash restart`
  end

  def self.reapply_mappings
    `curl -s -XPUT -d @#{Rails.root}/config/elasticsearch-mappings.json http://localhost:9200/_template/foo`
  end

  def self.restart_worker
   `sudo restart gridinit`
  end
  
end