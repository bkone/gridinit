require 'bundler/capistrano'
load 'deploy/assets'
set :rails_env, 'slave'
set :user, 'root'

set :applicationdir, '/var/gridnode'
set :application, 'gridinit'
set :domain, 'localhost'

set :scm, :none  
set :repository, "."  
set :deploy_via, :copy

default_run_options[:pty] = true
ssh_options[:port] = 22
ssh_options[:keys] = %w(~/.ssh/id_dsa)
set :chmod755, "app config db lib public vendor script script/* public/disp*"
set :use_sudo, false 

role :web, domain
role :app, domain
role :db,  domain, :primary => true

set :deploy_to, applicationdir
default_run_options[:pty] = true

if File.exists?(".git") and not(File.exists? "#{deploy_to}/shared/copy_cache")  
  set :copy_cache, "#{deploy_to}/shared/copy_cache"  
end  

ENV['TMP'] = '/var/tmp' 

namespace :uploads do
  task :setup, :except => { :no_release => true } do
    dirs = uploads_dirs.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
  end
  task :symlink, :except => { :no_release => true } do
    run "rm -rf #{release_path}/public/uploads"
    run "ln -nfs #{shared_path}/uploads #{release_path}/public/uploads"
  end
  task :register_dirs do
    set :uploads_dirs,    %w(uploads)
    set :shared_children, fetch(:shared_children) + fetch(:uploads_dirs)
  end

  task :writeconfig do
    database = <<-EOF
#{rails_env}:
  adapter: mysql2
  encoding: utf8
  database: gridnode
  username: root
  password: ""
EOF
    put database, "#{release_path}/config/database.yml"

    redis = <<-EOF
#{rails_env}:
  host: localhost
  port: 6379
EOF
    put redis, "#{release_path}/config/redis.yml"

    fog = <<-EOF
#{rails_env}:
  provider: AWS
  region: ap-southeast-1
  aws_access_key_id: ENTERYOURID
  aws_secret_access_key: ENTERYOURKEY
EOF
    put fog, "#{release_path}/config/fog.yml"

    procfile = <<-EOF
worker: bundle exec rake resque:work QUEUE=`curl -s ifconfig.me` RAILS_ENV=#{rails_env}
EOF
    put procfile, "#{release_path}/Procfile"

    run "cp #{release_path}/config/logstash-standalone #{release_path}/config/logstash.conf"

  end

  after       "deploy:finalize_update", "uploads:symlink", "uploads:writeconfig"
  on :start,  "uploads:register_dirs"
end