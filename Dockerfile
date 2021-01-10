FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG UNIFI_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ARG UNIFI_BRANCH="stable"
ARG DEBIAN_FRONTEND="noninteractive"

# install jre-openj9
RUN curl -L https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u275-b01_openj9-0.23.0/OpenJDK8U-jre_x64_linux_openj9_8u275b01_openj9-0.23.0.tar.gz | tar -xzf - -C /tmp/ && mv /tmp/jdk8u275-b01-jre/ /opt/jre
ENV PATH="/opt/jre/bin:${PATH}"
ADD java8-runtime-headless_99_all.deb /tmp/
RUN dpkg -i /tmp/java8-runtime-headless_99_all.deb

RUN \
 echo "**** install packages ****" && \
 apt-get update && \
 apt-get install -y \
	binutils \
	jsvc \
	libcap2 \
	logrotate \
	mongodb-server \
	wget && \
 echo "**** install unifi ****" && \
 if [ -z ${UNIFI_VERSION+x} ]; then \
	UNIFI_VERSION=$(curl -sX GET http://dl-origin.ubnt.com/unifi/debian/dists/${UNIFI_BRANCH}/ubiquiti/binary-amd64/Packages \
	|grep -A 7 -m 1 'Package: unifi' \
	| awk -F ': ' '/Version/{print $2;exit}' \
	| awk -F '-' '{print $1}'); \
 fi && \
 curl -o \
 /tmp/unifi.deb -L \
	"https://dl.ui.com/unifi/${UNIFI_VERSION}/unifi_sysvinit_all.deb" && \
 dpkg -i /tmp/unifi.deb && \
 echo "**** cleanup ****" && \
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY root/ /

# Volumes and Ports
WORKDIR /usr/lib/unifi
VOLUME /config
EXPOSE 8080 8443 8843 8880
