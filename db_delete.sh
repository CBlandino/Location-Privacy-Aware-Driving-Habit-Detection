#!/bin/bash 

# WARNING!!!! THESE MUST BE RUN FROM THE REPOS ROOT DIR

pg_ctl stop -D drive_guardDB 

rm -rf drive_guardDB 

rm db_log.log 
