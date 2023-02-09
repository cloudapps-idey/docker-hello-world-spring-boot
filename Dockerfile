# Maven build container 

#FROM maven:3.8.5-openjdk-11 AS maven_build

FROM fuse7/fuse-java-openshift-jdk11-rhel8:1.11-46

COPY pom.xml /tmp/

COPY src /tmp/src/

WORKDIR /tmp/

RUN mvn package


#maintainer 
MAINTAINER idey@yahoo.com
#expose port 8080
EXPOSE 8080

#default command
CMD java -jar /data/hello-world-0.1.0.jar

#copy hello world to docker image from builder image

COPY --from=maven_build /tmp/target/hello-world-0.1.0.jar /data/hello-world-0.1.0.jar
