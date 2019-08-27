#!/bin/bash

# Start MySQL (MariaDB) service
/etc/init.d/mysql start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start MariaDB: $status"
  exit $status
fi
if [ ! -f /mnt/mysql/webadm ]; then
  sed -i 's/mysql -u root -p -e "$SQL"/mysql -u root -e "$SQL"/' /opt/webadm/doc/scripts/create_mysqldb
  /opt/webadm/doc/scripts/create_mysqldb
fi

# Start RCDEVS ldap service
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
