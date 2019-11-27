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

## Configuration

You can mount a local folder at the contaner path `/fuseki/base` and put any fuseki configuration file in that folder. When the image is run for the first time a default configuration is creates in that directory. With this default configuration the 
environmenr variable `ADMIN_PASSWORD` can be used to set the password of the admin user
on startup.

## Extending

Any jar in the folder at the container path `/fuseki/extensions` is added to the classpath.

Any script in the folder at the container path `/fuseki/set-up-scripts` is executed when the container is started without `shiro.ini` file in the FUSEKI_BASE directory. These allows extending images to provide addition default configuration.
