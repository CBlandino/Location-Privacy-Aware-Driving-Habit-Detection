#!/bin/bash

# WARNING!!!! THESE MUST BE RUN FROM THE REPOS ROOT DIR

mkdir drive_guardDB 

pg_ctl init -D drive_guardDB 

pg_ctl start -D drive_guardDB -l db_log.log 

createdb dg_db 

psql -d dg_db -f dg_tables.sql 
