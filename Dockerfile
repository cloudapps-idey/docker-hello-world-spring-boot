 
FROM registry.redhat.io/ubi8/openjdk-11:1.14

LABEL src https://github.com/cloudapps-idey/docker-hello-world-spring-boot.git

# Source
COPY ./ /tmp/src/
USER root
RUN chmod -R "g=u" /tmp/src

# Maven build
USER 185
RUN /usr/local/s2i/assemble
RUN rm -rf /tmp/src/target
