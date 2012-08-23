class NodesController < ApplicationController
 
  def update
    node = Node.find_by_host!(params[:id])
    if permissions_on(node)
      node.update_attributes(:role => params[:role], :master => (params[:role] == 'slave' ? params[:master] : nil) )
      enqueue(node.host, :update_config)
      enqueue(node.host, :restart_services)
    end
    redirect_to :back
  end

  def destroy
    node = Node.find_by_host!(params[:id])
    if permissions_on(node)
      Resque::Job.create(@node.host, GridController, :destroy_on_aws, params)
      redirect_to :back, :notice => 'Node has been deleted.'
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