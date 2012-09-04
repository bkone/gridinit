#!/bin/bash
exec > >(tee /var/log/reinstall.log)
exec 2>&1
rm -rf /var/gridnode
mkdir /var/gridnode
chown -R ubuntu /var/gridnode
touch /var/log/gridnode-jmeter.log
touch /var/log/gridnode-watirwebdriver.log
touch /var/log/gridnode-stdout.log
touch /var/log/gridnode-stderr.log
touch /var/log/gridnode-errors.log
chown -R ubuntu /var/log/gridnode-*
cd /tmp
  wget -O gridinit.zip https://github.com/altentee/gridinit/zipball/master
  unzip gridinit.zip
  cd  altentee-gridinit*
  gem install bundler --no-ri --no-rdoc
  gem install capistrano --no-ri --no-rdoc
  ssh-keygen -t dsa -f /root/.ssh/id_dsa -N ''
  cat /root/.ssh/id_dsa.pub >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  cat - << EOS > ~/.ssh/config
Host *
CheckHostIP no
StrictHostKeyChecking no
EOS
mv config/selfdeploy.rb config/deploy.rb
export HOME="/root"
HOME="/root" cap HOSTS=localhost deploy:setup deploy:migrations
cd /tmp
rm -rf gridinit* altentee-gridinit*
chown -R ubuntu /var/gridnode

# restart dependent services
service apache2 restart
/etc/init.d/elasticsearch restart
/etc/init.d/logstash restart