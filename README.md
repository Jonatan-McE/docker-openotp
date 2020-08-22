# WebADM-OpenOTP

#### Simple Docker run command
```
docker run -d \  
-p 80:80 \  
-p 443:443 \  
-p 8080:8080 \  
-p 8443:8443 \  
-p 1812:1812 \  
--name openotp jonatanmc/openotp
```

## The following paths should be persisted
* /var/lib/mysql 
* /opt/slapd/conf
* /opt/slapd/data
* /opt/radiusd/conf
* /opt/webadm/conf
* /opt/webadm/pki

#### Simple Docker run command with persisted volumes
```
docker run -d \  
-p 80:80 \  
-p 443:443 \  
-p 8080:8080 \  
-p 8443:8443 \  
-p 1812:1812 \  
-v openotp_mysql:/var/lib/mysql \  
-v openotp_slapd_conf:/opt/slapd/conf \  
-v openotp_slapd_data:/opt/slapd/data \  
-v openotp_radiusd_conf:/opt/radiusd/conf \   
-v openotp_webadm_conf:/opt/webadm/conf \  
-v openotp_webadm_pki:/opt/webadm/pki \  
--name openotp jonatanmc/openotp
```

## First start

1. Login to the webadm web ui `https://<ip or url>/admin`  
*
  * User: cn=admin,o=root
  * Pass: password

2. Once logged in, Complete webADM installation by using the supplyed buttons to create any missing settings  
*
  * Database tables
  * WebADM proxy user
  * Default LDAP objects

3. After WebADM installation is complete. Logout and then back in again. There should be a pending SSL certificate 
requests from 127.0.0.1 that you need to acept within 5 min. This is for the radiusd service running localy  
*
  * User: admin
  * Pass: password

4. Configure the applications you want to use  
*
  * MFA Authentication server (OpenOTP)
  * SMS Hub server
  * SSH Public Key Server
  * User Self-Service Desk

## New license requirement for WebADM 2.0

As of webADM 2.0, even freeware installations require a licens file to start. You will need to ether retrive the the custom url 
that is created at startup and that can be seen when you output the container logs

- Docker: `docker logs <container name>`
- Kubernetes: `kubectl logs <pod name>`

Or create one here: https://cloud.rcdevs.com/freeware-license/

In both cases, you will need to copy or mount the license file into the container under: /opt/webadm/conf/

- Docker: `docker cp license.key <container name>:/opt/webadm/conf/license.key`
- Kubernetes: `kubectl cp license.key <pod name>:/opt/webadm/conf/license.key`

##### From RCDEV WebADM release notes:
*WebADM now requires a license file even in Freeware mode! This is because the Cloud
micro-services require your license metadata and authorizations in order to be used.
The Freeware license is connected to RCDevs license services and can be used on one
server only! Freeware licenses also requires an Internet connection, yet it can work
offline for a few weeks (without interacting with RCDevs license services).
You can get a WebADM freeware license at https://cloud.rcdevs.com/freeware-license/.
Note that all the previously available freeware features are maintained in WebADM v2.*
