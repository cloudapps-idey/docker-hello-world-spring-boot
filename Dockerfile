FROM registry.redhat.io/ubi8/openjdk-11:1.15

ENV FUSE_JAVA_IMAGE_NAME="ubi8/openjdk-11" \
    FUSE_JAVA_IMAGE_VERSION="1.5" \
    JOLOKIA_VERSION="1.7.1.redhat-00001" \
    PATH=$PATH:"/usr/local/s2i" \
    AB_JOLOKIA_PASSWORD_RANDOM="true" \
    AB_JOLOKIA_AUTH_OPENSHIFT="true" \
    JAVA_DATA_DIR="/deployments/data"

# Some version information
LABEL com.redhat.dev-mode="JAVA_DEBUG:false" \
      src=https://github.com/cloudapps-idey/docker-hello-world-spring-boot.git \
      com.redhat.dev-mode.port="JAVA_DEBUG_PORT:5005"

# Source
COPY ./ /tmp/src/

# Temporary switch to root
USER root

# Install unzip via SCL
RUN microdnf --noplugins install -y unzip && microdnf --noplugins clean all


# Use /dev/urandom to speed up startups & Add jboss user to the root group
RUN echo securerandom.source=file:/dev/urandom >> /usr/lib/jvm/java/conf/security/java.security \
 && usermod -g root -G jboss jboss


# Jolokia agent
RUN mkdir -p /opt/jolokia/etc
COPY ./jolokia/jolokia.jar /opt/jolokia/jolokia.jar
ADD ./jolokia/jolokia-opts /opt/jolokia/jolokia-opts
RUN chmod 444 /opt/jolokia/jolokia.jar \
 && chmod 755 /opt/jolokia/jolokia-opts \
 && chmod 775 /opt/jolokia/etc \
 && chgrp root /opt/jolokia/etc

EXPOSE 8778


# S2I scripts + README
COPY s2i /usr/local/s2i
RUN rm /usr/local/s2i/scl-enable-maven && chmod 755 /usr/local/s2i/*
ADD README.md /usr/local/s2i/usage.txt

# Add run script as /opt/run-java/run-java.sh and make it executable
COPY run-java.sh /opt/run-java/
RUN chmod 755 /opt/run-java/run-java.sh

# Adding run-env.sh to set app dir
COPY run-env.sh /opt/run-java/run-env.sh
RUN chmod 755 /opt/run-java/run-env.sh


# Necessary to permit running with a randomised UID
RUN mkdir -p /deployments/data \
 && chmod -R "g+rwX" /deployments \
 && chown -R jboss:root /deployments \
 && chmod -R "g+rwX" /home/jboss \
 && chown -R jboss:root /home/jboss \
 && chmod 664 /etc/passwd

# S2I requires a numeric, non-0 UID. This is the UID for the jboss user in the base image

USER 185
RUN mkdir -p /home/jboss/.m2
COPY settings.xml /home/jboss/.m2/settings.xml

RUN /usr/local/s2i/assemble
RUN rm -rf /tmp/src/target
