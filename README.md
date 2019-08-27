# docker-openotp

Example run command

docker run -d --rm -v openotp_conf:/mnt -v openotp_webadm_conf:/opt/webadm/conf -p 80:80 -p 443:443 -p 8080:8080 -p 8443:8443 -p 1812:1812 --name openotp openotp
