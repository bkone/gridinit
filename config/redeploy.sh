#!/bin/bash
# must run this as root
# curl -L https://raw.github.com/altentee/gridinit/master/config/redeploy.sh | bash
exec > >(tee /var/log/reinstall.log)
exec 2>&1
rm -rf /var/gridnode
rm -rf /tmp/altentee*
mkdir /var/gridnode
chown -R ubuntu /var/gridnode
cd /tmp
wget -O gridinit.zip https://github.com/altentee/gridinit/zipball/master
unzip gridinit.zip
cd  altentee-gridinit*
gem install bundler --no-ri --no-rdoc
gem install capistrano --no-ri --no-rdoc
rm -f /root/.ssh/id*
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