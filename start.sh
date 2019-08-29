#!/bin/bash

# Start MySQL (MariaDB) service
if [ ! "$(ls -A /var/lib/mysql/)" ]; then
  cp -r --preserve=all /var/lib/.mysql/* /var/lib/mysql/
fi
/etc/init.d/mysql start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start MariaDB: $status"
  exit $status
fi

# Start RCDEVS ldap service
if [ ! "$(ls -A /opt/slapd/conf/)" ]; then
  cp -r --preserve=all /opt/slapd/.conf/* /opt/slapd/conf/
fi
if [ ! "$(ls -A /opt/slapd/data/)" ]; then
  cp -r --preserve=all /opt/slapd/.data/* /opt/slapd/data/
fi
if [ ! -f /opt/slapd/temp/.setup ]; then
  /opt/slapd/bin/setup silent
else
  /opt/slapd/bin/slapd start
  status=$?
  if [ $status -ne 0 ]; then
    echo "Failed to start Slapd: $status"
    exit $status
  fi
fi

# Start RCDEVS webadm service
if [ ! "$(ls -A /opt/webadm/conf/)" ]; then
  cp -r --preserve=all /opt/webadm/.conf/* /opt/webadm/conf/
fi
if [ ! "$(ls -A /opt/webadm/pki/)" ]; then
  cp -r --preserve=all /opt/webadm/.pki/* /opt/webadm/pki/
fi
if [ ! -f /var/lib/mysql/webadm ]; then
  sed -i 's/mysql -u root -p -e "$SQL"/mysql -u root -e "$SQL"/' /opt/webadm/doc/scripts/create_mysqldb
  /opt/webadm/doc/scripts/create_mysqldb
fi
if [ ! -f /opt/webadm/temp/.setup ]; then
  /opt/webadm/bin/setup silent
fi
/opt/webadm/bin/webadm start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start WebADM $status"
  exit $status
fi

# Start RCDEVS radius service
if [ ! "$(ls -A /opt/radiusd/conf/)" ]; then
  cp -r --preserve=all /opt/radiusd/.conf/* /opt/radiusd/conf/
fi
if [ ! -f /opt/radiusd/temp/.setup ]; then
  echo "-- Waiting for WebADM setup to complete before continuing --"
  while [[ ! `wget --no-check-certificate --no-cookies --timeout=5 --delete -S https://127.0.0.1/cacert/ 2>&1 | grep 'HTTP/1.1 200'` ]]; do
    sleep 5
  done
  printf '127.0.0.1\n\ny\ny\n' | /opt/radiusd/bin/setup
fi
/opt/radiusd/bin/radiusd start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start Radiusd $status"
  exit $status
fi

# Service monitoring loop
echo "-- Starting process monitoring loop --"
while sleep 60; do
  ps aux |grep mysql |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep rcdevs-slapd |grep -q -v grep
  PROCESS_2_STATUS=$?
  ps aux |grep webadm-httpd |grep -q -v grep
  PROCESS_3_STATUS=$?
  ps aux |grep rcdevs-radiusd |grep -q -v grep
  PROCESS_4_STATUS=$?
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 -o $PROCESS_3_STATUS -ne 0 -o $PROCESS_4_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done
