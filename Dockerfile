# openhab image 
FROM multiarch/ubuntu-debootstrap:amd64-wily
#FROM multiarch/ubuntu-debootstrap:armhf-wily   # arch=armhf
#FROM multiarch/ubuntu-debootstrap:arm64-wily   # arch=arm64
ARG ARCH=amd64

ARG DOWNLOAD_URL="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab-online/target/openhab-online-2.0.0-SNAPSHOT.zip"
ARG DOWNLOAD_HABMIN2="https://github.com/cdjackson/HABmin2/blob/master/output/org.openhab.ui.habmin_2.0.0.SNAPSHOT-0.1.6.jar"

ENV APPDIR="/openhab" OPENHAB_HTTP_PORT='8080' OPENHAB_HTTPS_PORT='8443' EXTRA_JAVA_OPTS=''

# Install Basepackages
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
      software-properties-common \
      sudo \
      unzip \
      wget \
    && rm -rf /var/lib/apt/lists/*

# Install Oracle Java
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install --no-install-recommends -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Add openhab user
RUN adduser --disabled-password --gecos '' --home ${APPDIR} openhab &&\
    adduser openhab sudo &&\
    adduser openhab dialout &&\
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/openhab

WORKDIR ${APPDIR}

# Install Openhab
RUN \
    wget -nv -O /tmp/openhab.zip ${DOWNLOAD_URL} &&\
    unzip -q /tmp/openhab.zip -d ${APPDIR} &&\
    rm /tmp/openhab.zip

# Install habmin
RUN wget -nv -O ${APPDIR}/addons/org.openhab.ui.habmin_2.0.0.SNAPSHOT-0.1.6.jar ${DOWNLOAD_HABMIN2}

# Create log files
RUN mkdir -p ${APPDIR}/userdata/logs && touch ${APPDIR}/userdata/logs/openhab.log

# Copy directories for host volumes
RUN cp -a /openhab/userdata /openhab/userdata.dist && \
    cp -a /openhab/conf /openhab/conf.dist
COPY files/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

RUN chown -R openhab:openhab ${APPDIR}
USER openhab
# Expose volume with configuration and userdata dir
VOLUME ${APPDIR}/conf ${APPDIR}/userdata ${APPDIR}/addons
EXPOSE 8080 8443 5555
CMD ["server"]
