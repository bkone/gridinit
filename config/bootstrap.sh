#!/bin/bash
exec > >(tee /var/log/install.log)
exec 2>&1
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
function file_update() { sed -i '\|$1|d' $2; echo $1 >> $2; }
function file_touch() { mkdir -p `dirname $1`; touch $1; chmod $2 $1; }
function apt() { echo "==> Updating packages" 
  file_update "deb http://archive.ubuntu.com/ubuntu/ `cat /etc/lsb-release | grep CODENAME | cut -d= -f2` main restricted universe multiverse" /etc/apt/sources.list
  file_update "deb http://archive.ubuntu.com/ubuntu/ `cat /etc/lsb-release | grep CODENAME | cut -d= -f2`-updates main restricted universe multiverse" /etc/apt/sources.list
  file_update "deb http://archive.canonical.com/ubuntu/ `cat /etc/lsb-release | grep CODENAME | cut -d= -f2` partner" /etc/apt/sources.list
  apt-get update -y 2>&1 >> /dev/null
  apt-get upgrade -y 2>&1 >> /dev/null
}
function os() { echo "==> Modifying OS parameters"
  if ! grep 'session required pam_limits' /etc/pam.d/login
  then
    locale-gen en_AU.UTF-8 en_US.UTF-8
    cd /opt
    echo 'fs.file-max=65535' >> /etc/sysctl.conf
    echo 'net.ipv4.ip_local_port_range = 1024 65000' >> /etc/sysctl.conf
    sysctl -p
    echo '* soft nofile 1000000' >> /etc/security/limits.conf
    echo '* hard nofile 1000000' >> /etc/security/limits.conf
    echo 'session required pam_limits.so' >> /etc/pam.d/login
    ulimit -n 1000000
    ulimit -n -H
    echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
    echo '10240' > /proc/sys/net/core/somaxconn
  fi
}
function ntp() { echo "==> Setting timezone" 
  echo 'Australia/Melbourne' | tee /etc/timezone
  dpkg-reconfigure --frontend noninteractive tzdata
  cat - << EOS > /etc/cron.d/clock
0 0 * * * * root ntpdate ntp.ubuntu.com pool.ntp.org 2>&1 >> /dev/null
EOS
}
function motd() { echo "==> Updating message of the day" 
  file_touch /etc/motd.tail 0644
  cat - << EOS > /etc/motd.tail
                               
            ,   /) ,      ,    
   _   __     _(/   __     _/_ 
  (_/_/ (__(_(_(__(_/ (__(_(__ 
 .-/                           
(_/                                   

Last built: `date`
EOS
}
function essential() { echo "==> Installing essential packages"
  apt-get install -y build-essential binutils-doc autoconf flex bison git-core git g++ vim zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake unzip openssl libreadline6 libreadline6-dev curl wget make rrdtool openjdk-6-jre libmysqlclient-dev libapache2-mod-passenger libcurl4-openssl-dev chkconfig apache2 apache2-dev multitail redis-server httping acl nodejs sendmail
  file_touch /root/.ssh/known_hosts 0700
  cat - << EOS > /root/.ssh/known_hosts
github.com,207.97.227.239 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
EOS
  git config --global user.name 'gridnode'
  git config --global user.email 'support@gridinit.com'
}
function users() { echo "==> Check/add Ubuntu user"
  if [ ! -d /home/ubuntu ]; then
    useradd -d /home/ubuntu -m ubuntu
    adduser ubuntu sudo
    echo '%sudo ALL=NOPASSWD: ALL' >> /etc/sudoers
    adduser ubuntu admin
    chsh -s /bin/bash ubuntu
  fi
}
function rubies() { echo "==> Installing Ruby 1.9.2 and Passenger"
  if [ ! -f /usr/bin/ruby1.9.1 ]; then
    apt-get remove -y ruby1.8
    apt-get install -y ruby1.9.1 ruby1.9.1-dev libxml2-dev libxslt1-dev libsqlite3-dev
    update-alternatives --set ruby /usr/bin/ruby1.9.1 
    update-alternatives --set gem /usr/bin/gem1.9.1 
    gem install bundler passenger --no-ri --no-rdoc
    yes | passenger-install-apache2-module
  fi
}
function gridnode() { echo "==> Creating Gridnode directories"
  if [ ! -d /var/gridnode ]; then
    mkdir /var/gridnode
    chown -R ubuntu /var/gridnode
    touch /var/log/gridnode-jmeter.log
    touch /var/log/gridnode-watirwebdriver.log
    touch /var/log/gridnode-stdout.log
    touch /var/log/gridnode-stderr.log
    touch /var/log/gridnode-errors.log
    chown -R ubuntu /var/log/gridnode-*
  fi
}
function apache() { echo "==> Installing Apache"
  if [ ! -f /etc/apache2/sites-available/gridnode ]; then
    cd /etc/apache2
    cat - << EOS > /etc/apache2/sites-available/gridnode
ErrorLog /var/log/apache2/error.log
LogLevel warn
CustomLog /var/log/apache2/access.log combined
ServerName 127.0.0.1
RailsEnv production
<VirtualHost *:80>
  DocumentRoot /var/gridnode/current/public
  <Directory /var/gridnode/current/public>
    Allow from all
    Options -MultiViews
  </Directory>
  Alias /logs /var/log
</VirtualHost>
EOS
    cat - << EOS > /etc/apache2/mods-enabled/passenger.conf
<IfModule mod_passenger.c>
  PassengerRoot /var/lib/gems/1.9.1/gems/`ls /var/lib/gems/1.9.1/gems | grep passenger`
  PassengerRuby /usr/bin/ruby
</IfModule>
EOS
    cat - << EOS > /etc/apache2/mods-enabled/passenger.load
LoadModule passenger_module /var/lib/gems/1.9.1/gems/`ls /var/lib/gems/1.9.1/gems | grep passenger`/ext/apache2/mod_passenger.so
EOS
    a2dissite default
    a2ensite gridnode
    /etc/init.d/apache2 restart
  fi
}
function mysql() { echo "==> Installing MySQL"
  if [ ! -f /usr/bin/mysql ]; then
    apt-get install -y mysql-server
    mysqladmin -u root --password='' create gridnode 2>&1 >> /dev/null
  fi
}
function selfdeploy() { echo "==> Self-deploy Gridinit"
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
}
function elasticsearch() { echo "==> Installing Elasticsearch"
  mkdir -p /opt/elasticsearch
  mkdir -p /opt/elasticsearch/data
  cd /opt/elasticsearch
  ES_PACKAGE=elasticsearch-0.19.8.zip
  ES_DIR=${ES_PACKAGE%%.zip}
  SITE=https://github.com/downloads/elasticsearch/elasticsearch
  if [ ! -d "$ES_DIR" ] ; then
    wget --no-check-certificate $SITE/$ES_PACKAGE
    unzip $ES_PACKAGE
  fi
  mv /opt/elasticsearch/elasticsearch-0.19.8/* .
  rm -rf /opt/elasticsearch/elasticsearch-0.19.8*
  wget -O /opt/elasticsearch/elasticsearch-servicewrapper.tar.gz https://github.com/elasticsearch/elasticsearch-servicewrapper/tarball/master
  tar xvf /opt/elasticsearch/elasticsearch-servicewrapper.tar.gz
  mv /opt/elasticsearch/*servicewrapper*/service /opt/elasticsearch/bin/
  rm -rf /opt/elasticsearch/*servicewrapper*
  /opt/elasticsearch/bin/service/elasticsearch install
  /opt/elasticsearch/bin/plugin -install mobz/elasticsearch-head # http://127.0.0.1:9200/_plugin/head/
  perl -pi -e 's|# path.data.*|path.data: /opt/elasticsearch/data|g' /opt/elasticsearch/config/elasticsearch.yml
  /etc/init.d/elasticsearch start
}
function grok() { echo "==> Installing Grok"
  if [ ! -f /var/grok/grok_1.20101030.3088_amd64.deb ]; then  
    mkdir /var/grok
    cd /var/grok
    apt-get install -y bison ctags flex gperf libtokyocabinet-dev libtokyocabinet8 tokyocabinet-bin libevent-dev gperf libpcre3-dev
    apt-get install -y libevent-1.4-2 libevent-core-1.4-2 libevent-extra-1.4-2
    apt-get autoremove -f -y
    wget http://semicomplete.googlecode.com/files/grok_1.20101030.3088_amd64.deb
    # wget https://launchpad.net/~semiosis/+archive/grok-1/+build/2838872/+files/grok_1.20110708-1ubuntu~ppa4~natty1_i386.deb
    dpkg -i grok_1.20101030.3088_amd64.deb
    apt-get -f install -y
  fi
}
function logstash() { echo "==> Installing Logstash"
  if [ ! -f /opt/logstash/lib/logstash.jar ]; then  
    mkdir -p /opt/logstash/bin
    mkdir -p /opt/logstash/lib
    mkdir -p /opt/logstash/pid
    mkdir -p /opt/logstash/data
    cd /opt/logstash
    wget -O /opt/logstash/lib/logstash.jar http://semicomplete.com/files/logstash/logstash-1.1.1-monolithic.jar
    wget -O /opt/logstash/wrapper.tar.gz http://wrapper.tanukisoftware.com/download/3.5.15/wrapper-linux-x86-64-3.5.15.tar.gz
    # wget -O /opt/logstash/wrapper.tar.gz http://wrapper.tanukisoftware.com/download/3.5.15/wrapper-linux-x86-32-3.5.15.tar.gz
    # wget -O /opt/logstash/wrapper.tar.gz http://wrapper.tanukisoftware.com/download/3.5.15/wrapper-macosx-universal-64-3.5.15.tar.gz
    tar xvf /opt/logstash/wrapper.tar.gz
    cp /opt/logstash/wrapper*/src/bin/sh.script.in /opt/logstash/bin/logstash
    cp /opt/logstash/wrapper*/bin/wrapper /opt/logstash/bin/
    cp /opt/logstash/wrapper*/lib/libwrapper.so /opt/logstash/lib/
    cp /opt/logstash/wrapper*/lib/wrapper.jar /opt/logstash/lib/
    rm -rf /opt/logstash/wrapper*
    touch /var/log/gridnode-logstash.log
    touch /var/log/gridnode-wrapper.log
    chown ubuntu:ubuntu /var/log/gridnode-logstash.log
    chown ubuntu:ubuntu /var/log/gridnode-wrapper.log
    chown -R ubuntu:ubuntu /opt/logstash
    file=/opt/logstash/bin/logstash
    perl -pi -e 's|APP_NAME=.*|APP_NAME="logstash"|g' $file
    perl -pi -e 's|APP_LONG_NAME=.*|APP_LONG_NAME="Logstash"|g' $file
    perl -pi -e 's|WRAPPER_CONF=.*|WRAPPER_CONF="/var/gridnode/current/config/wrapper.conf"|g' $file
    perl -pi -e 's|PIDDIR=.*|PIDDIR="/opt/logstash/pid"|g' $file
    perl -pi -e 's|RUN_AS_USER=.*|RUN_AS_USER="ubuntu"|g' $file
    chmod +x /opt/logstash/bin/logstash
    /opt/logstash/bin/logstash install
  fi
}
function xvfb() { echo "==> Installing Xvfb" 
  if [ ! -f /usr/bin/Xvfb ]; then
    apt-get install -y xvfb
    gem install watir-webdriver --no-ri --no-rdoc
    gem install watir-webdriver-performance --no-ri --no-rdoc
    gem install watirgrid --no-ri --no-rdoc
    gem install headless --no-ri --no-rdoc
  fi
}
function firefox() { echo "==> Installing Firefox"
  if [ ! -f /usr/bin/firefox ]; then
    apt-get install -y firefox
    mkdir /var/firefox
    cd /var/firefox
    wget https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi
    wget http://getfirebug.com/releases/netexport/netExport-0.8b21.xpi
    wget http://ftp.mozilla.org/pub/mozilla.org/addons/5369/yslow-3.1.0-fx.xpi
  fi
}
function jmeter() { echo "==> Installing JMeter"
  if [ ! -f /usr/share/jmeter/lib/ext/plugins.zip ]; then
    apt-get install -y jmeter
    cd /tmp
    wget http://apache.mirror.aussiehq.net.au/jmeter/binaries/apache-jmeter-2.6.zip
    unzip apache-jmeter-2.6.zip
    cp -R apache-jmeter-2.6/* /usr/share/jmeter/
    rm -rf apache-jmeter-2.6*
    wget -O /usr/share/jmeter/lib/ext/plugins.zip http://jmeter-plugins.googlecode.com/files/JMeterPlugins-0.4.2.zip 
    unzip /usr/share/jmeter/lib/ext/plugins.zip -d /usr/share/jmeter/lib/ext/ 2>&1 >> /dev/null
  fi
}
function wkhtmltoimage() { echo "==> Installing WebKit HTML to Image"
  if [ ! -d /var/wkhtmltopdf ]; then
    mkdir /var/wkhtmltopdf
    chown -R ubuntu /var/wkhtmltopdf
    cd /var/wkhtmltopdf
    wget http://wkhtmltopdf.googlecode.com/files/wkhtmltoimage-0.11.0_rc1-static-amd64.tar.bz2
    # wget https://wkhtmltopdf.googlecode.com/files/wkhtmltoimage-0.11.0_rc1-static-i386.tar.bz2
    tar xvf wkhtmltoimage*
  fi
}
function webdis() { echo "==> Installing WebDis"
  if [ ! -d /var/webdis ]; then  
    git clone https://github.com/nicolasff/webdis.git /var/webdis
    cd /var/webdis
    make
    perl -pi -e 's|"daemonize":.+|"daemonize": true,|g' /var/webdis/webdis.json
    perl -pi -e 's|"disabled":.+|"disabled": ["DEBUG", "FLUSHDB", "FLUSHALL"]|g' /var/webdis/webdis.json
    perl -pi -e 's|"enabled":.+|"disabled": ["DEBUG", "FLUSHDB", "FLUSHALL"]|g' /var/webdis/webdis.json
    ./webdis
  fi
}
function monit() { echo "==> Installing Monit"
  if [ ! -d /etc/monit/monitrc ]; then
    apt-get install -y monit   
    cat - << EOS > /etc/monit/monitrc
    set daemon 15
    set logfile /var/log/monit.log
    set idfile /var/lib/monit/id
    set statefile /var/lib/monit/state
    set eventqueue
    basedir /var/lib/monit/events
    slots 100
    set httpd port 2812 and
    allow 0.0.0.0/0.0.0.0
    include /etc/monit/conf.d/*
EOS
    service monit restart
  fi
}
function firewall() { echo "==> Update Firewall"
  ufw default deny
  ufw allow 443   # https
  ufw allow 80    # http
  ufw allow 22    # ssh
  ufw allow 2812  # monit
  ufw allow 6379  # redis
  ufw allow 7379  # webdis
  ufw enable      # only used on non-EC2 instances
}
function rclocal() { echo "==> Update rc.local"
  cat - << EOS > /etc/rc.local
#!/bin/sh
/var/webdis/webdis
chown -R ubuntu /var/firefox
exit 0
EOS
}
function cleanup() { echo "==> Cleanup Install" 
  apt-get autoremove -y
  updatedb
  service apache2 restart
}
# configure and deploy
apt
os
ntp
motd
essential
users
rubies
gridnode
apache
mysql
selfdeploy
elasticsearch
grok
logstash
xvfb
firefox
jmeter
wkhtmltoimage
webdis
monit
firewall
rclocal
cleanup
# sed -ie 's/Port 22/Port 443/' /etc/ssh/sshd_config
# service ssh restart