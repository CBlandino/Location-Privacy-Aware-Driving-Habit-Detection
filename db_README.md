# drive guard DB init instructions 

before starting please ensure that postgresql **AND** all of its package utilitys are installed (especially pg_ctl and createdb) 

1. create a dir for the db cluster im naming mine drive_guardDB 

2. init the cluster 
```
pg_ctl init -D drive_guardDB
```

3. start the cluster
```
pg_ctl start -D drive_guardDB -l db_log.log 
```
`-l` specifies the log file u can name this whatever you like

4. create the database
```
createdb dg_db 
```
PLEASE NAME IT 'dg_db' THE SCRIPT WILL NOT WORK IF YOU DONT

5. run the user and table init script 
```
psql -d dg_db -f dg_tables.sql 
```

you should see some output about creating tables and such

6. verify that the db and tables have been created

```
psql dg_db 
```

this'll drop u in the postgres shell. run `\l' and `\d` to make sure you see the db and all the tables
