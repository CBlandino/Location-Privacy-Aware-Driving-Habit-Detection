postgres go bindings: https://pkg.go.dev/github.com/lib/pq@v1.10.9


one static connection os probably fine for now, but it might be good to look into connection pooling as we get crazier with go routines


woah stdlib sql handles connection pooling for u appartently... u just have to set some pool parameters and your kinda good to open up as many connections as u want 

```
// Set the connection pool parameters
db.SetMaxOpenConns(10)  // Maximum number of open connections
db.SetMaxIdleConns(5)   // Maximum number of idle connections
db.SetConnMaxLifetime(0) // Connections are not closed automatically after this duration
```
