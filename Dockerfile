FROM debian:stable-slim

WORKDIR /root/

# Install basic system components
RUN apt-get update \
	&& apt-get install wget px nano -y \ 
	&& rm -rf /var/lib/apt/lists/*

# Instal MariaDB
RUN apt-get update \
	&& apt-get install mariadb-server -y \ 
	&& rm -rf /var/lib/apt/lists/*

# Install Rcdev WebADM and OpenOTP
RUN wget https://www.rcdevs.com/repos/debian/rcdevs-release_1.0.0-0_all.deb \ 
	&& apt-get install ./rcdevs-release_1.0.0-0_all.deb \
	&& rm ./rcdevs-release_1.0.0-0_all.deb \
	&& apt-get update \
	&& apt-get install webadm openotp radiusd smshub selfdesk rcdevs-slapd spankey -y \
	&& rm -rf /var/lib/apt/lists/* 

# Create backup copy of original configureation files that get wipped of by persistent volume mounts
RUN cp -r --preserve=all /var/lib/mysql /var/lib/.mysql \
	&& cp -r --preserve=all /opt/slapd/conf /opt/slapd/.conf \
	&& cp -r --preserve=all /opt/slapd/data /opt/slapd/.data \
	&& cp -r --preserve=all /opt/webadm/conf /opt/webadm/.conf \
	&& cp -r --preserve=all /opt/webadm/pki /opt/webadm/.pki \
	&& cp -r --preserve=all /opt/radiusd/conf /opt/radiusd/.conf

# Create symlinks for the .setup file from the temp folder to the config folder that should be persisted 
RUN ln -s /opt/slapd/conf/.setup /opt/slapd/temp/.setup \
	&& ln -s /opt/webadm/conf/.setup /opt/webadm/temp/.setup \
	&& ln -s /opt/radiusd/conf/.setup /opt/radiusd/temp/.setup 

ADD ./start.sh /
CMD /start.sh
