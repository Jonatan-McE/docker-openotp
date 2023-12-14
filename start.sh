#!/bin/bash

# Start MySQL (MariaDB) service
if [ ! "$(ls -A /var/lib/mysql/)" ]; then
  echo ">Copying default MySQL/MariaDB config files"
  cp -r --preserve=all /var/lib/.mysql/* /var/lib/mysql/
fi
echo ">Starting MariaDB service"
/etc/init.d/mariadb start
status=$?
if [ $status -ne 0 ]; then
  echo ">Failed to start MariaDB: $status"
  exit $status
fi

# Start RCDEVS ldap service
if [ ! "$(ls -A /opt/slapd/conf/)" ]; then
  echo ">Copying default SLAPD config files"
  cp -r --preserve=all /opt/slapd/.conf/* /opt/slapd/conf/
fi
if [ ! "$(ls -A /opt/slapd/data/)" ]; then
  echo ">Copying default SLAPD data files"
  cp -r --preserve=all /opt/slapd/.data/* /opt/slapd/data/
fi
if [ ! -f /opt/slapd/temp/.setup ]; then
  echo ">Running SLAPD silent setup"
  /opt/slapd/bin/setup silent
else
  echo ">Starting SLAPD service"
  /opt/slapd/bin/slapd start
  status=$?
  if [ $status -ne 0 ]; then
    echo ">Failed to start Slapd: $status"
    exit $status
  fi
fi

# Start RCDEVS webadm service
if [ ! "$(ls -A /opt/webadm/conf/)" ]; then
  echo ">Copying default WebADM config files"
  cp -r --preserve=all /opt/webadm/.conf/* /opt/webadm/conf/
fi
if [ ! "$(ls -A /opt/webadm/pki/)" ]; then
  echo ">Copying default WebADM pki files"
  cp -r --preserve=all /opt/webadm/.pki/* /opt/webadm/pki/
fi
if [ ! -d /var/lib/mysql/webadm ]; then
  echo ">Creating MySQL/MariaDB webadm database schema"
  /opt/webadm/doc/scripts/create_mysqldb -s -d webadm -u webadm -p webadm -w 127.0.0.1 -n
fi
if [ ! -f /opt/webadm/temp/.setup ]; then
  echo ">Running WebADM silent setup"
  /opt/webadm/bin/setup silent
  if [ -z "$WEBADM_PROXYUSR_PASS" ]; then
    echo ">Replacing WebADM proxy user password"
    sed -i 's/proxy_password.*/proxy_password "'"$WEBADM_PROXYUSER_PASS"'"/' /opt/webadm/conf/webadm.conf
#  else
#    sed -i 's/proxy_password.*/proxy_password "password"/' /opt/webadm/conf/webadm.conf
  fi
fi
echo ">Starting WebADM service"
/opt/webadm/bin/webadm start
status=$?
if [ $status -ne 0 ]; then
  echo ">Failed to start WebADM $status"
  exit $status
fi

# Start RCDEVS radius service
if [ ! "$(ls -A /opt/radiusd/conf/)" ]; then
  echo ">Copying default RADIUSD  config files"
  cp -r --preserve=all /opt/radiusd/.conf/* /opt/radiusd/conf/
fi
if [ ! -f /opt/radiusd/temp/.setup ]; then
  echo ">-- Login to the WebADM webUI and complete the installation (https://<ip/url>/admin)  --"
  echo ">-- Username: cn=admin,o=root                                                         --"
  echo ">-- Password: password                                                                --"
  while [[ ! `wget --no-check-certificate --no-cookies --timeout=5 --delete -S https://127.0.0.1/cacert/ 2>&1 | grep 'HTTP/1.1 200'` ]]; do
    sleep 5
  done
  printf '127.0.0.1\n\ny\ny\n' | /opt/radiusd/bin/setup
fi
echo ">Starting RADIUSD service"
/opt/radiusd/bin/radiusd start
status=$?
if [ $status -ne 0 ]; then
  echo ">Failed to start Radiusd $status"
  exit $status
fi

# Service monitoring loop
echo ">-- Starting process monitoring loop --"
while sleep 60; do
  ps aux |grep mariadbd |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep rcdevs-slapd |grep -q -v grep
  PROCESS_2_STATUS=$?
  ps aux |grep webadm-httpd |grep -q -v grep
  PROCESS_3_STATUS=$?
  ps aux |grep rcdevs-radiusd |grep -q -v grep
  PROCESS_4_STATUS=$?
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 -o $PROCESS_3_STATUS -ne 0 -o $PROCESS_4_STATUS -ne 0 ]; then
    echo ">One of the processes has exited."
    exit 1
  fi
done
