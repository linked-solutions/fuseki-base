FROM maven:3.9.5-eclipse-temurin-17

EXPOSE 3030

# Configure Maven with a mirror for better reliability
RUN mkdir -p /root/.m2 && \
    echo '<?xml version="1.0" encoding="UTF-8"?>' > /root/.m2/settings.xml && \
    echo '<settings>' >> /root/.m2/settings.xml && \
    echo '  <mirrors>' >> /root/.m2/settings.xml && \
    echo '    <mirror>' >> /root/.m2/settings.xml && \
    echo '      <id>central-mirror</id>' >> /root/.m2/settings.xml && \
    echo '      <name>Maven Central Mirror</name>' >> /root/.m2/settings.xml && \
    echo '      <url>https://repo1.maven.org/maven2</url>' >> /root/.m2/settings.xml && \
    echo '      <mirrorOf>central</mirrorOf>' >> /root/.m2/settings.xml && \
    echo '    </mirror>' >> /root/.m2/settings.xml && \
    echo '  </mirrors>' >> /root/.m2/settings.xml && \
    echo '</settings>' >> /root/.m2/settings.xml

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
COPY config-default.ttl /config.ttl

ENV FUSEKI_HOME=/fuseki/home
ENV FUSEKI_BASE=/fuseki/base

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["sh", "-c", "java $JAVA_OPTS -cp /fuseki/home/fuseki.jar:/fuseki/extensions/* org.apache.jena.fuseki.cmd.FusekiCmd --config=/config.ttl"]