# Fuseki Base Docker Image

Yet another [Apache Fuseki](http://jena.apache.org/documentation/fuseki2/index.html) Docker distribution.

## Project goals

The Docker image provided by this distribution shall:

 * Allow the full Fuseki configuration
 * Allow adding extensions
 * Use Maven to get an up-to-date version of Fuseki
 * Be extendible to allow creation of custom distributions as extending images

 ## Building

    docker -t linkedsolutions/fuseki-base . 

## Running 

    docker-compose up

or 

    docker run --rm -v `pwd`/base:/fuseki/base -p 3030:3030 linkedsolutions/fuseki-base

You might have '`pwd`/base' with the full path to the FUSEKI_BASE directory, see 
https://jena.apache.org/documentation/fuseki2/fuseki-layout.html to learn avout the contents of this directory.
