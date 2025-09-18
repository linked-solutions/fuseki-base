# Fuseki Base Docker Image

Yet another [Apache Fuseki](http://jena.apache.org/documentation/fuseki2/index.html) Docker distribution.

## Project goals

The Docker image provided by this distribution shall:

 * Allow the full Fuseki configuration
 * Allow adding extensions
 * Use Maven to get an up-to-date version of Fuseki
 * Be extendible to allow creation of custom distributions as extending images

## Building

    docker build -t linkedsolutions/fuseki-base . 

## Running 

    docker-compose up

or 

    docker run --rm -v `pwd`/base:/fuseki/base -p 3030:3030 linkedsolutions/fuseki-base

You might have '`pwd`/base' with the full path to the FUSEKI_BASE directory, see 
https://jena.apache.org/documentation/fuseki2/fuseki-layout.html to learn about the contents of this directory.

## Configuration

You can mount a local folder at the container path `/fuseki/base` and put any fuseki configuration file in that folder. When the image is run for the first time a default configuration is created in that directory. With this default configuration the 
environment variable `ADMIN_PASSWORD` can be used to set the password of the admin user
on startup.

## Extending

Any jar in the folder at the container path `/fuseki/extensions` is added to the classpath.

Any script in the folder at the container path `/fuseki/set-up-scripts` is executed when the container is started without `shiro.ini` file in the FUSEKI_BASE directory. These allows extending images to provide additional default configuration.

## Examples

All example files mentioned in this documentation are available in the [`examples/`](examples/) directory.

### Prerequisites

Build the Docker image first:
```bash
docker build -t linkedsolutions/fuseki-base .
```

### Example 1: Creating and Using a Dataset from Command Line

#### Step 1: Start Fuseki with an in-memory dataset

```bash
# Start Fuseki with an in-memory dataset named "test-dataset"
docker run --rm -p 3030:3030 linkedsolutions/fuseki-base \
  sh -c "java \$JAVA_OPTS -cp /fuseki/home/fuseki.jar org.apache.jena.fuseki.cmd.FusekiCmd --mem --port 3030 /test-dataset"
```

The server will be available at `http://localhost:3030` with:
- Dataset endpoint: `/test-dataset`
- SPARQL query endpoint: `/test-dataset/query`
- SPARQL update endpoint: `/test-dataset/update`
- Graph Store HTTP Protocol: `/test-dataset/data`

#### Step 2: Create sample data file

Create a file named `sample-data.ttl`:
```turtle
@prefix ex: <http://example.org/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix dc: <http://purl.org/dc/elements/1.1/> .

ex:person1 a foaf:Person ;
    foaf:name "Alice Smith" ;
    foaf:age 30 ;
    foaf:knows ex:person2 .

ex:person2 a foaf:Person ;
    foaf:name "Bob Johnson" ;
    foaf:age 25 ;
    foaf:knows ex:person1 .

ex:book1 a ex:Book ;
    dc:title "Learning SPARQL" ;
    dc:creator "Alice Smith" ;
    ex:publishedYear 2023 .

ex:book2 a ex:Book ;
    dc:title "Semantic Web Technologies" ;
    dc:creator "Bob Johnson" ;
    ex:publishedYear 2022 .
```

#### Step 3: Add data to the dataset

```bash
# Upload the data using HTTP POST
curl -X POST -H "Content-Type: text/turtle" \
  --data-binary "@sample-data.ttl" \
  "http://localhost:3030/test-dataset/data"
```

Expected response:
```json
{ 
  "count" : 16 ,
  "tripleCount" : 16 ,
  "quadCount" : 0
}
```

#### Step 4: Query the dataset

Create a query file `query-people.sparql`:
```sparql
PREFIX foaf: <http://xmlns.com/foaf/0.1/>

SELECT ?person ?name ?age
WHERE {
  ?person a foaf:Person ;
          foaf:name ?name ;
          foaf:age ?age .
}
ORDER BY ?age
```

Execute the query:
```bash
curl -X POST -H "Content-Type: application/sparql-query" \
  --data-binary "@query-people.sparql" \
  "http://localhost:3030/test-dataset/query"
```

Expected response:
```json
{ "head": {
    "vars": [ "person" , "name" , "age" ]
  } ,
  "results": {
    "bindings": [
      { 
        "person": { "type": "uri" , "value": "http://example.org/person2" } ,
        "name": { "type": "literal" , "value": "Bob Johnson" } ,
        "age": { "type": "literal" , "datatype": "http://www.w3.org/2001/XMLSchema#integer" , "value": "25" }
      } ,
      { 
        "person": { "type": "uri" , "value": "http://example.org/person1" } ,
        "name": { "type": "literal" , "value": "Alice Smith" } ,
        "age": { "type": "literal" , "datatype": "http://www.w3.org/2001/XMLSchema#integer" , "value": "30" }
      }
    ]
  }
}
```

### Example 2: Persistent Dataset with TDB

#### Step 1: Create a persistent dataset directory

```bash
mkdir -p ./fuseki-data/databases
mkdir -p ./fuseki-data/configuration
```

#### Step 2: Start Fuseki with persistent TDB storage

```bash
# Start Fuseki with a persistent TDB dataset (with update capability)
docker run --rm -p 3030:3030 \
  -v $(pwd)/fuseki-data:/fuseki-data \
  linkedsolutions/fuseki-base \
  sh -c "java \$JAVA_OPTS -cp /fuseki/home/fuseki.jar org.apache.jena.fuseki.cmd.FusekiCmd --loc=/fuseki-data/databases/mydata --update --port 3030 /mydata"
```

#### Step 3: Add and query data

The same data upload and query commands from Example 1 work here, just replace `test-dataset` with `mydata` in the URLs.

**Note**: Add the `--update` flag when starting Fuseki to enable write operations (INSERT, UPDATE, DELETE). Without this flag, the dataset will be read-only.

### Example 3: Configuration-based Setup

#### Step 1: Create a dataset configuration

Create `config.ttl`:
```turtle
@prefix :        <#> .
@prefix fuseki:  <http://jena.apache.org/fuseki#> .
@prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix tdb:     <http://jena.hpl.hp.com/2008/tdb#> .
@prefix ja:      <http://jena.hpl.hp.com/2005/11/Assembler#> .

<#service_tdb_all> rdf:type fuseki:Service ;
    rdfs:label                      "Books Dataset" ;
    fuseki:name                     "books" ;
    fuseki:serviceQuery             "query" ;
    fuseki:serviceQuery             "sparql" ;
    fuseki:serviceUpdate            "update" ;
    fuseki:serviceUpload            "upload" ;
    fuseki:serviceReadWriteGraphStore      "data" ;
    fuseki:serviceReadGraphStore       "get" ;
    fuseki:dataset           <#tdb_dataset_readwrite> ;
    .

<#tdb_dataset_readwrite> rdf:type      tdb:DatasetTDB ;
    tdb:location "/fuseki-data/databases/books" ;
    tdb:unionDefaultGraph true ;
    .
```

#### Step 2: Start Fuseki with configuration

```bash
docker run --rm -p 3030:3030 \
  -v $(pwd)/fuseki-data:/fuseki-data \
  -v $(pwd)/config.ttl:/config.ttl \
  linkedsolutions/fuseki-base \
  sh -c "java \$JAVA_OPTS -cp /fuseki/home/fuseki.jar org.apache.jena.fuseki.cmd.FusekiCmd --config=/config.ttl"
```

### Example 4: Using Docker Compose

#### Step 1: Create docker-compose.yml

```yaml
version: '3'
services:
  fuseki:
    image: "linkedsolutions/fuseki-base"
    ports:
      - "3030:3030"
    volumes:
      - ./fuseki-data:/fuseki/base
    environment:
      - ADMIN_PASSWORD=your-secure-password
```

#### Step 2: Start the service

```bash
docker-compose up -d
```

#### Step 3: Access the web interface

Open your browser and go to `http://localhost:3030`. Log in with:
- Username: `admin`
- Password: `your-secure-password` (or `admin` if not set)

### Example 5: Batch Data Operations

#### Step 1: Prepare multiple data files

Create `books.ttl`:
```turtle
@prefix ex: <http://example.org/> .
@prefix dc: <http://purl.org/dc/elements/1.1/> .

ex:book1 a ex:Book ;
    dc:title "Learning SPARQL" ;
    dc:creator "Alice Smith" ;
    ex:publishedYear 2023 .

ex:book2 a ex:Book ;
    dc:title "Semantic Web Technologies" ;
    dc:creator "Bob Johnson" ;
    ex:publishedYear 2022 .
```

Create `authors.ttl`:
```turtle
@prefix ex: <http://example.org/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

ex:person1 a foaf:Person ;
    foaf:name "Alice Smith" ;
    foaf:age 30 .

ex:person2 a foaf:Person ;
    foaf:name "Bob Johnson" ;
    foaf:age 25 .
```

#### Step 2: Upload multiple files

```bash
# Upload books data
curl -X POST -H "Content-Type: text/turtle" \
  --data-binary "@books.ttl" \
  "http://localhost:3030/test-dataset/data"

# Upload authors data  
curl -X POST -H "Content-Type: text/turtle" \
  --data-binary "@authors.ttl" \
  "http://localhost:3030/test-dataset/data"
```

#### Step 3: Complex query across datasets

Create `complex-query.sparql`:
```sparql
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX ex: <http://example.org/>

SELECT ?authorName ?bookTitle ?year
WHERE {
  ?book a ex:Book ;
        dc:title ?bookTitle ;
        dc:creator ?authorName ;
        ex:publishedYear ?year .
  ?author a foaf:Person ;
          foaf:name ?authorName .
}
ORDER BY ?year ?authorName
```

Execute:
```bash
curl -X POST -H "Content-Type: application/sparql-query" \
  --data-binary "@complex-query.sparql" \
  "http://localhost:3030/test-dataset/query"
```

### Example 6: Data Updates

#### Step 1: Insert new data via SPARQL Update

Create `insert-data.sparql`:
```sparql
PREFIX ex: <http://example.org/>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>

INSERT DATA {
  ex:person3 a foaf:Person ;
    foaf:name "Charlie Brown" ;
    foaf:age 35 .
    
  ex:book3 a ex:Book ;
    dc:title "RDF in Practice" ;
    dc:creator "Charlie Brown" ;
    ex:publishedYear 2024 .
}
```

Execute the update:
```bash
curl -X POST -H "Content-Type: application/sparql-update" \
  --data-binary "@insert-data.sparql" \
  "http://localhost:3030/test-dataset/update"
```

#### Step 2: Modify existing data

Create `update-data.sparql`:
```sparql
PREFIX ex: <http://example.org/>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>

DELETE { ex:person1 foaf:age ?oldAge }
INSERT { ex:person1 foaf:age 31 }
WHERE { ex:person1 foaf:age ?oldAge }
```

Execute:
```bash
curl -X POST -H "Content-Type: application/sparql-update" \
  --data-binary "@update-data.sparql" \
  "http://localhost:3030/test-dataset/update"
```

### Web Interface

Fuseki provides a web interface at `http://localhost:3030` where you can:
- Browse datasets
- Execute SPARQL queries interactively  
- Upload data files
- Monitor server statistics
- Manage dataset configurations

### Common HTTP Status Codes

- `200 OK`: Successful query/operation
- `204 No Content`: Successful update with no response body
- `400 Bad Request`: Malformed SPARQL or invalid data
- `401 Unauthorized`: Authentication required
- `404 Not Found`: Dataset or endpoint not found
- `500 Internal Server Error`: Server error (check logs)

### Example 7: Lucene Text Indexing Configuration

For advanced text search capabilities, you can configure Fuseki with Lucene indexing. Note that this requires the jena-text extension.

#### Step 1: Create Lucene configuration

Create `config-lucene.ttl`:
```turtle
@prefix :        <#> .
@prefix fuseki:  <http://jena.apache.org/fuseki#> .
@prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix tdb:     <http://jena.hpl.hp.com/2008/tdb#> .
@prefix ja:      <http://jena.hpl.hp.com/2005/11/Assembler#> .
@prefix text:    <http://jena.apache.org/text#> .

<#service_tdb_lucene> rdf:type fuseki:Service ;
    rdfs:label                      "TDB with Lucene" ;
    fuseki:name                     "books" ;
    fuseki:serviceQuery             "query" ;
    fuseki:serviceQuery             "sparql" ;
    fuseki:serviceUpdate            "update" ;
    fuseki:serviceUpload            "upload" ;
    fuseki:serviceReadWriteGraphStore      "data" ;
    fuseki:serviceReadGraphStore       "get" ;
    fuseki:dataset           <#dataset> ;
    .

<#dataset> rdf:type text:TextDataset ;
    text:dataset <#tdb_dataset> ;
    text:index <#indexLucene> ;
    .

<#tdb_dataset> rdf:type tdb:DatasetTDB ;
    tdb:location "/fuseki-data/databases/books-lucene" ;
    tdb:unionDefaultGraph true ;
    .

<#indexLucene> a text:TextIndexLucene ;
    text:directory <file:/fuseki-data/lucene-index> ;
    text:entityMap <#entMap> ;
    .

<#entMap> a text:EntityMap ;
    text:entityField      "uri" ;
    text:defaultField     "text" ;
    text:langField        "lang" ;
    text:graphField       "graph" ;
    text:map (
         [ text:field "text" ; 
           text:predicate rdfs:label ]
         [ text:field "title" ; 
           text:predicate <http://purl.org/dc/elements/1.1/title> ]
         [ text:field "name" ; 
           text:predicate <http://xmlns.com/foaf/0.1/name> ]
         ) .
```

#### Step 2: Prepare text-searchable data

Create `lucene-data.ttl`:
```turtle
@prefix ex: <http://example.org/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix dc: <http://purl.org/dc/elements/1.1/> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

ex:book1 a ex:Book ;
    dc:title "Learning SPARQL" ;
    rdfs:label "A comprehensive guide to SPARQL query language for semantic web" ;
    dc:creator "Alice Smith" ;
    ex:publishedYear 2023 .

ex:book2 a ex:Book ;
    dc:title "Semantic Web Technologies" ;
    rdfs:label "Introduction to RDF, SPARQL, and linked data technologies" ;
    dc:creator "Bob Johnson" ;
    ex:publishedYear 2022 .

ex:person1 a foaf:Person ;
    foaf:name "Alice Smith" ;
    rdfs:label "Expert in SPARQL and semantic web technologies" ;
    foaf:age 30 .
```

#### Step 3: Create text search queries

Create `query-text-search.sparql`:
```sparql
PREFIX text: <http://jena.apache.org/text#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>

SELECT ?subject ?score ?title ?name ?label
WHERE {
  (?subject ?score) text:query "SPARQL" .
  OPTIONAL { ?subject dc:title ?title }
  OPTIONAL { ?subject foaf:name ?name }
  OPTIONAL { ?subject rdfs:label ?label }
}
ORDER BY DESC(?score)
```

#### Step 4: Start Fuseki with Lucene configuration

**Note**: This example requires the jena-text extension jar to be available in the classpath. In production setups, you would add the jena-text jar to the `/fuseki/extensions` directory.

```bash
# Assuming you have the jena-text extension available
docker run --rm -p 3030:3030 \
  -v $(pwd)/fuseki-data:/fuseki-data \
  -v $(pwd)/config-lucene.ttl:/config-lucene.ttl \
  linkedsolutions/fuseki-base \
  sh -c "java \$JAVA_OPTS -cp /fuseki/home/fuseki.jar org.apache.jena.fuseki.cmd.FusekiCmd --config=/config-lucene.ttl"
```

#### Step 5: Upload data and perform text search

Upload the data:
```bash
curl -X POST -H "Content-Type: text/turtle" \
  --data-binary "@lucene-data.ttl" \
  "http://localhost:3030/books/data"
```

Execute text search:
```bash
curl -X POST -H "Content-Type: application/sparql-query" \
  --data-binary "@query-text-search.sparql" \
  "http://localhost:3030/books/query"
```

Expected results will include books and people related to "SPARQL" with relevance scores.

### Tips

1. **Data Formats**: Fuseki supports RDF/XML, Turtle, N-Triples, JSON-LD, and more
2. **Authentication**: Use HTTP Basic Auth for protected endpoints
3. **Performance**: Use TDB for better performance with large datasets
4. **Monitoring**: Check server logs and the `/$/stats` endpoint for monitoring
5. **Backup**: Regularly backup your TDB database directories
6. **Text Search**: For full-text search capabilities, add jena-text jars to `/fuseki/extensions`
7. **Memory**: Increase JVM memory with `JAVA_OPTS="-Xmx4g"` for large datasets
8. **Security**: Always change default passwords in production environments
