#!/usr/bin/env python3

# Python script that only does one thing: Creates a concepts_of_interest table or view that is required by MENDS queries.
# It uses the same input arguments as the original gnenerate-input.py code from which this is derived

# -*- coding: utf-8 -*-

import os
import argparse
import pandas as pd 
import sqlalchemy
 
from google.cloud import storage
from sqlalchemy import create_engine
from sqlalchemy import text
from dotenv import load_dotenv

def parse_sql(sqlfile, database, schema):
    queries = []

    with open(sqlfile,"r") as inf:
        inrows = inf.readlines()
    sql = ""
    for row in inrows:
        # replace sql params
        row = row.replace("@cdmDatabaseSchema",database + '.' + schema)
        sql = sql + row

    return queries
def process_sql():
    clparse = argparse.ArgumentParser(description='Create name-array JSON from SQL statements')
    clparse.add_argument('--sqlfile',required=True, default=None, help='Name of local file with SQL statements')
    clparse.add_argument('--database', required=True, type=str.lower, choices =["mssql","oracle", "postgres","postgresql","pg","bigquery"], help='Specify DBMS: one of MSSQL, Oracle, Postgres, or BigQuery (only BQ currently supported)')
    clparse.add_argument('--dbargs', required=True,help='database/schema (Bigquery: "project/dataset)')
    args = clparse.parse_args()

    sqlfile = os.path.abspath(args.sqlfile)
    dbargs = args.dbargs.split('/',1)
    database = dbargs[0]
    schema = dbargs[1]
    dbms = args.database
#
# dotenv() used for PG variables: PG_USERNAME, PG_PASSWORD, PG_IP, PG_PORT
# Postgres database name and schema are passed in -dbargs command line args
#

    load_dotenv()

  # TODO: Generalize by DBTYPE
  # TODO: Use .env for Google parms rather than assume local environment

    if dbms == 'bigquery':
        db_url = "bigquery://" + database + "/" + schema
    elif (dbms == "postgres" or dbms == "postgresql" or dbms == "pg"):
        pg_user = os.getenv("PG_USERNAME")                                   
        pg_password = os.getenv("PG_PASSWORD")                                  
        pg_host = os.getenv("PG_IP")
        pg_port = os.getenv("PG_PORT")
        db_url  = 'postgresql+psycopg2://' + pg_user + ':' + pg_password + '@' + pg_host + ':' + pg_port + '/'  + database + '?options=-csearch_path%3D' + schema
    else:
        print("Error: Should never be here")
        exit()

    db_engine = create_engine(db_url, echo=True)
    with engine.connect() as conn:
        query=text(sql)
        conn.execute(query)



if __name__ == '__main__':
    process_sql()
