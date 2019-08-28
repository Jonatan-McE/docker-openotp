FROM debian:stable-slim

WORKDIR /root/

# Install basic system components
RUN apt-get update \
	&& apt-get install wget px -y \ 
	&& rm -rf /var/lib/apt/lists/*

# Instal MariaDB
RUN apt-get update \
	&& apt-get install mariadb-server -y \ 
	&& rm -rf /var/lib/apt/lists/*

# Install Rcdev WebADM and OpenOTP
RUN wget https://www.rcdevs.com/repos/debian/rcdevs-release_1.0.0-0_all.deb \ 
	&& apt-get install ./rcdevs-release_1.0.0-0_all.deb \
	&& apt-get update \
	&& apt-get install webadm openotp radiusd smshub selfdesk rcdevs-slapd -y \
	&& rm -rf /var/lib/apt/lists/* 

RUN mkdir -p /mnt/slapd && mkdir -p /mnt/webadm && mkdir -p /mnt/radiusd \
	&& mv /opt/slapd/conf /opt/slapd/data /mnt/slapd/ \
	&& mv /opt/webadm/pki /mnt/webadm/ \
	&& mv /opt/radiusd/conf /mnt/radiusd/ \ 
	&& ln -s /mnt/slapd/* /opt/slapd/ \
	&& ln -s /mnt/webadm/* /opt/webadm/ \
	&& ln -s /mnt/radiusd/* /opt/radiusd/

RUN ln -s /opt/slapd/conf/.setup /opt/slapd/temp/.setup \
	&& ln -s /opt/webadm/conf/.setup /opt/webadm/temp/.setup \
	&& ln -s /opt/radiusd/conf/.setup /opt/radiusd/temp/.setup 

ADD ./start.sh /
CMD /start.sh
