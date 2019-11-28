FROM maven:3.6.2-jdk-11

EXPOSE 3030

COPY pom.xml /sources/pom.xml

RUN cd sources && mvn -DskipTests=true package -DfinalName=fuseki
RUN mkdir -p /fuseki/extensions
RUN mkdir /fuseki/home /fuseki/base\
    && cp -r /sources/target/webapp /fuseki/home/ \
    && cp /sources/target/fuseki.jar /fuseki/home/

COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh
COPY set-up-scripts /fuseki/set-up-scripts
COPY set-up-resources /fuseki/set-up-resources

ENV FUSEKI_HOME=/fuseki/home
ENV FUSEKI_BASE=/fuseki/base

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD java $JAVA_OPTS -cp /fuseki/home/fuseki.jar:/fuseki/extensions/* org.apache.jena.fuseki.cmd.FusekiCmd