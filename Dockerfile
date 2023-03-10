
#FROM registry.redhat.io/fuse7/fuse-java-openshift-rhel8:1.11
FROM registry.redhat.io/ubi8/openjdk-11:1.15

LABEL src https://github.com/cloudapps-idey/docker-hello-world-spring-boot.git

# Source
COPY ./ /tmp/src/

#USER root
#RUN chmod -R "g=u" /tmp/src

# Temporary switch to root
USER root

# Install unzip via SCL
RUN microdnf --noplugins install -y unzip && microdnf --noplugins clean all


# Use /dev/urandom to speed up startups & Add jboss user to the root group
RUN echo securerandom.source=file:/dev/urandom >> /usr/lib/jvm/java/conf/security/java.security \
 && usermod -g root -G jboss jboss
 
 RUN chgrp -R 0 /tmp/src && \
    chmod -R g=u /tmp/src

# Maven build
USER 185


RUN /usr/local/s2i/assemble
RUN rm -rf /tmp/src/target

#ADD jolokia-jvm-1.7.2 /opt/jolokia-jvm-1.7.2

#ENTRYPOINT exec java -javaagent:/opt/jolokia-jvm-17.2.jar 

