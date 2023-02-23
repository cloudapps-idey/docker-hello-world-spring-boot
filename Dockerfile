 FROM registry.redhat.io/ubi8/openjdk-11
 
 LABEL src https://github.com/cloudapps-idey/docker-hello-world-spring-boot.git

# Source
COPY ./ /tmp/src/
USER root
RUN chmod -R "g=u" /tmp/src

ENV JAVA_IMAGE_NAME="ubi8/openjdk-11" \
    JAVA_IMAGE_VERSION="1.11" \
    JOLOKIA_VERSION="1.7.1.redhat-00001" \
    PROMETHEUS_JMX_EXPORTER_VERSION="0.3.1.redhat-00006" \
    PATH=$PATH:"/usr/local/s2i" \
    AB_JOLOKIA_PASSWORD_RANDOM="true" \
    AB_JOLOKIA_AUTH_OPENSHIFT="true" \
    JAVA_DATA_DIR="/deployments/data"


# Temporary switch to root
USER root

# Install unzip via SCL
RUN microdnf --noplugins install -y unzip && microdnf --noplugins clean all


# Use /dev/urandom to speed up startups.
RUN echo securerandom.source=file:/dev/urandom >> /usr/lib/jvm/java/jre/lib/security/java.security \
 && usermod -g root -G jboss jboss

# Jolokia agent
RUN mkdir -p /opt/jolokia/etc
COPY "artifacts/org/jolokia/jolokia-jvm/${JOLOKIA_VERSION}/jolokia-jvm-${JOLOKIA_VERSION}.jar" /opt/jolokia/jolokia.jar
#COPY "jolokia-jvm-${JOLOKIA_VERSION}.jar" /opt/jolokia/jolokia.jar
ADD jolokia-opts /opt/jolokia/jolokia-opts
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

# Use the run script as default since we are working as an hybrid image which can be
# used directly to. (If we were a plain s2i image we would print the usage info here)
CMD [ "/usr/local/s2i/run" ]
