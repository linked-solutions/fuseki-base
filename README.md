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

### Basic Dataset Operations

#### Start Fuseki with a dataset

```bash
# In-memory dataset
docker run --rm -p 3030:3030 linkedsolutions/fuseki-base \
  sh -c "java \$JAVA_OPTS -cp /fuseki/home/fuseki.jar org.apache.jena.fuseki.cmd.FusekiCmd --mem --port 3030 /books"

# Persistent TDB dataset (create directory first: mkdir -p ./fuseki-data/databases/books)
docker run --rm -p 3030:3030 \
  -v $(pwd)/fuseki-data:/fuseki-data \
  linkedsolutions/fuseki-base \
  sh -c "java \$JAVA_OPTS -cp /fuseki/home/fuseki.jar org.apache.jena.fuseki.cmd.FusekiCmd --loc=/fuseki-data/databases/books --update --port 3030 /books"
```

#### Upload data

```bash
curl -X POST -H "Content-Type: text/turtle" \
  --data-binary "@examples/sample-data.ttl" \
  "http://localhost:3030/books/data"
```

#### Query data

```bash
# Query people
curl -X POST -H "Content-Type: application/sparql-query" \
  --data-binary "@examples/query-people.sparql" \
  "http://localhost:3030/books/query"

# Query books  
curl -X POST -H "Content-Type: application/sparql-query" \
  --data-binary "@examples/query-books.sparql" \
  "http://localhost:3030/books/query"
```

#### Update data

```bash
curl -X POST -H "Content-Type: application/sparql-update" \
  --data-binary "@examples/insert-data.sparql" \
  "http://localhost:3030/books/update"
```

### Configuration-based Setup

```bash
# Using a configuration file
docker run --rm -p 3030:3030 \
  -v $(pwd)/fuseki-data:/fuseki/base \
  -v $(pwd)/examples/config.ttl:/config.ttl \
  linkedsolutions/fuseki-base \
  sh -c "java \$JAVA_OPTS -cp /fuseki/home/fuseki.jar org.apache.jena.fuseki.cmd.FusekiCmd --config=/config.ttl"
```

### Docker Compose With Configuration

```yaml
services:
  fuseki:
    image: "linkedsolutions/fuseki-base"
    ports:
      - "3030:3030"
    volumes:
      - ./fuseki-data:/fuseki/base
      - ./examples/config.ttl:/config.ttl
    environment:
      - ADMIN_PASSWORD=your-secure-password
    command: ["sh", "-c", "java $$JAVA_OPTS -cp /fuseki/home/fuseki.jar org.apache.jena.fuseki.cmd.FusekiCmd --config=/config.ttl"]
```

### Text Search with Lucene

#### Start with Lucene
```bash
docker run --rm -p 3030:3030 \
  -v $(pwd)/fuseki-data:/fuseki-data \
  -v $(pwd)/examples/config-lucene.ttl:/config-lucene.ttl \
  linkedsolutions/fuseki-base \
  sh -c "java \$JAVA_OPTS -cp /fuseki/home/fuseki.jar org.apache.jena.fuseki.cmd.FusekiCmd --config=/config-lucene.ttl"
```

#### Upload searchable data
```bash
curl -X POST -H "Content-Type: text/turtle" \
  --data-binary "@examples/lucene-data.ttl" \
  "http://localhost:3030/books/data"
```

#### Text search query
```bash
curl -X POST -H "Content-Type: application/sparql-query" \
  --data-binary "@examples/query-text-search.sparql" \
  "http://localhost:3030/books/query"
```

### Comparison: Regular vs Text Search Queries

With the **same dataset name** (`/books`), you can see the difference:

**Regular SPARQL query** (works without Lucene):
```sparql
PREFIX dc: <http://purl.org/dc/elements/1.1/>
SELECT ?book ?title WHERE {
  ?book dc:title ?title .
  FILTER(CONTAINS(LCASE(?title), "sparql"))
}
```

**Text search query** (requires Lucene configuration):
```sparql
PREFIX text: <http://jena.apache.org/text#>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
SELECT ?book ?score ?title WHERE {
  (?book ?score) text:query "SPARQL" .
  ?book dc:title ?title .
}
```

The text search provides relevance scoring and performs much better on large datasets.

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

### Tips

1. **Data Formats**: Fuseki supports RDF/XML, Turtle, N-Triples, JSON-LD, and more
2. **Authentication**: Use HTTP Basic Auth for protected endpoints
3. **Performance**: Use TDB for better performance with large datasets
4. **Monitoring**: Check server logs and the `/$/stats` endpoint for monitoring
5. **Backup**: Regularly backup your TDB database directories
6. **Text Search**: Full-text search with Lucene is now included by default
7. **Memory**: Increase JVM memory with `JAVA_OPTS="-Xmx4g"` for large datasets
8. **Security**: Always change default passwords in production environments