class NodesController < ApplicationController
  before_filter :require_admin!, :except => [:index, :update]
  protect_from_forgery :except => [:update, :restart]

  def update
    node = Node.find_by_host!(params[:id])
    node.update_attributes(:role => params[:role], :master => params[:master])
    write_config(node)
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
  end

  def write_config(node)
    logstash = File.read("#{Rails.root}/config/logstash-#{node.role}").gsub('gridinit.com', node.master ? node.master : '')
    File.open("#{Rails.root}/config/logstash.conf", 'w+'){|f| f << logstash } 
  end

  def self.restart_redis
    thread_execute "sudo /etc/init.d/redis-server restart"
  end

  def self.restart_elasticsearch
    thread_execute "sudo /etc/init.d/elasticsearch restart"
  end

  def self.restart_logstash
    thread_execute "sudo /etc/init.d/logstash restart"
  end

  def self.reapply_mappings
    thread_execute "curl -XPUT -d @#{Rails.root}/config/elasticsearch-mappings.json http://localhost:9200/_template/foo"
  end

  def self.thread_execute(cmd)
    Thread.new { `#{cmd}` }
  end
  
end