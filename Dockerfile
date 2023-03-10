 
FROM registry.redhat.io/fuse7/fuse-java-openshift-rhel8:1.11

LABEL src https://github.com/cloudapps-idey/docker-hello-world-spring-boot.git

# Source
COPY ./ /tmp/src/
USER root
RUN chmod -R "g=u" /tmp/src

# Maven build
USER 185
RUN /usr/local/s2i/assemble
RUN rm -rf /tmp/src/target

#ADD jolokia-jvm-1.7.2 /opt/jolokia-jvm-1.7.2

#ENTRYPOINT exec java -javaagent:/opt/jolokia-jvm-17.2.jar 
