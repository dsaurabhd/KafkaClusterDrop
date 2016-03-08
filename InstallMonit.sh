#!/bin/sh

#Stop monit service if any
/etc/init.d/monit stop && update-rc.d -f monit remove
rm -rf /usr/bin/monit

# download monit binary
cd /opt
wget http://wevestorage.blob.core.windows.net/monit/monit-5.16-linux-x64.tar.gz
tar -xzvf monit-5.16-linux-x64.tar.gz
mv monit-5.16 monit

#Create directories
mkdir -p /opt/monit/log
mkdir -p /opt/monit/lib/events
mv /opt/monit/bin/monit /usr/bin/
rm -rf /opt/monit/conf/monitrc

# Create the monitrc file
cat > /etc/monitrc << EOL
set daemon 120
set logfile  /opt/monit/log/monit.log
set idfile /opt/monit/lib/id
set statefile /opt/monit/lib/state
set eventqueue
    basedir /opt/monit/lib/events
    slots 1000
set mmonit http://weveuser:$1@$3:8080/collector
set httpd port 2812 and
    allow localhost
    allow $3
    allow weveadmin:$2
    allow @monit
    allow @users readonly
include /opt/monit/conf/*
EOL

chmod 0700 /etc/monitrc

#Create the upstart init script
cat > /etc/init/monit.conf << EOL
description "Monit service manager"
limit core unlimited unlimited
start on runlevel [2345]
stop on starting rc RUNLEVEL=[016]
expect daemon
respawn
exec /usr/bin/monit -c /etc/monitrc
pre-stop exec /usr/bin/monit -c /etc/monitrc quit
EOL

# Reload config and start
initctl reload-configuration
start monit

monit status