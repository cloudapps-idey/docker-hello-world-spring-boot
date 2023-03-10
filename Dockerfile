FROM registry.redhat.io/ubi8/openjdk-11:1.15

ENV FUSE_JAVA_IMAGE_NAME="ubi8/openjdk-11" \
    FUSE_JAVA_IMAGE_VERSION="1.5" \
    JOLOKIA_VERSION="1.7.1.redhat-00001" \
    PATH=$PATH:"/usr/local/s2i" \
    AB_JOLOKIA_PASSWORD_RANDOM="true" \
    AB_JOLOKIA_AUTH_OPENSHIFT="true" \
    JAVA_DATA_DIR="/deployments/data"

# Some version information
LABEL name="$FUSE_JAVA_IMAGE_NAME" \
      version="$FUSE_JAVA_IMAGE_VERSION" \
      maintainer="Otavio Piske <opiske@redhat.com>" \
      summary="Build and run Spring Boot-based integration applications" \
      description="Build and run Spring Boot-based integration applications" \
      com.redhat.component="ubi8/openjdk-11-container" \
      io.fabric8.s2i.version.maven="3.3.3-1.el7" \
      io.fabric8.s2i.version.jolokia="1.7.1.redhat-00001" \
      io.fabric8.s2i.version.prometheus.jmx_exporter="0.3.1.redhat-00006" \
      io.k8s.description="Build and run Spring Boot-based integration applications" \
      io.k8s.display-name="Fuse for OpenShift" \
      io.openshift.tags="builder,java,fuse" \
      io.openshift.s2i.scripts-url="image:///usr/local/s2i" \
      io.openshift.s2i.destination="/tmp" \
      org.jboss.deployments-dir="/deployments" \
      com.redhat.deployments-dir="/deployments" \
      com.redhat.dev-mode="JAVA_DEBUG:false" \
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

# Copy licenses
RUN mkdir -p /opt/fuse/licenses
COPY licenses.css /opt/fuse/licenses
COPY licenses.xml /opt/fuse/licenses
COPY licenses.html /opt/fuse/licenses
COPY apache_software_license_version_2.0-apache-2.0.txt /opt/fuse/licenses

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
