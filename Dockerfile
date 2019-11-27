FROM maven:3.6.2-jdk-11

EXPOSE 3030

ADD pom.xml /sources/pom.xml

RUN cd sources && mvn -DskipTests=true package -DfinalName=fuseki
RUN mkdir -p /fuseki/extensions
RUN mkdir /fuseki/home /fuseki/base\
    && cp -r /sources/target/webapp /fuseki/home/ \
    && cp /sources/target/fuseki.jar /fuseki/home/

ADD docker-entrypoint.sh /
ADD set-up-scripts /fuseki/set-up-scripts
ADD set-up-resources /fuseki/set-up-resources

ENV FUSEKI_HOME=/fuseki/home
ENV FUSEKI_BASE=/fuseki/base

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java", "-cp", "/fuseki/home/fuseki.jar:/fuseki/extensions/*", "org.apache.jena.fuseki.cmd.FusekiCmd"]