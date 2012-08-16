class NodesController < ApplicationController
  before_filter :require_admin!, :except => [:index]
  protect_from_forgery :except => [:update, :restart]

  def update
    node = Node.find_by_host!(params[:id])
    node.update_attributes(:role => params[:role], :master => params[:master])
    update_config(node)
    enqueue(node.host, :restart_services)
    redirect_to :back
  end

  def restart
    nodes = params[:id] == 'all' ? Node.all : Node.find_all_by_id(params[:id])
    nodes.each { |node| enqueue(node.host, :restart_services) }
    redirect_to :back
  end

  def enqueue(queue, action)
    Resque::Job.create(queue, NodesController, action)
  end

  def self.perform(action)
    self.send(action.to_sym)
  end

  private

  def self.restart_services
    self.restart_elasticsearch
    self.restart_logstash
    self.reapply_mappings
    self.restart_rails
  end

  def update_config(node)
    logstash = File.read("#{Rails.root}/config/logstash-#{node.role}").gsub('gridinit.com', node.master ? node.master : '127.0.0.1')
    File.open("#{Rails.root}/config/logstash.conf", 'w+'){|f| f << logstash } 
    
    redis = File.read("#{Rails.root}/config/redis.yml").gsub(/host:.+/, node.master ? "host: #{node.master}" : "host: localhost")
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

  def self.restart_rails
   `sudo /etc/init.d/apache2 restart`
  end
  
end