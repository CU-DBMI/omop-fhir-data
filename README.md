# meds-on-fhir-example-data

# Overview
The repo holds OMOP JSON data sets that can be used to run the OMOP-to-FHIR pipeline available in the [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo. Using these data sets obviates the need for access to an instance of an OMOP CDM running on an RDBMS. Each branch represents a different data set. Branch names following the same naming convention: Source-Query Method-Rows:
* Source: the original data source. Usually a public domain deidentified data resource. Currently only Synthea data sets have been created.
* Query Method: currently one of {random, cohort}. Random data sets do not maintain referential integrity but will always have a fixed number of rows per table. Cohort-based data sets maintain referential integrity and will have the fixed number of patients. However cohort-based queries  will not have a fixed number of rows in other tables in order to maintain referential integrity within a patient's data. 
* Rows: The number of rows in a table. See above for difference between random and cohort queries.

An example is the current branch: synthea-random-20. This branch has OMOP JSON data that was created using Synthea, using a random query, with each table having 20 rows.

## Usage
The [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo contains a script that mounts one of the branches from this directory as a submodule that is used as its input OMOP JSON as the starting point for the OMOP-to-FHIR conversion pipeline. See the README description on the MENDS-on-FHIR repo and how to alter the appropriate environment variable to mount a different branch as they become available.

### Future work
A "tools" branch is being created that will run a Docker-based Postgresql DBMS preloaded with one or more OMOP data sources that can be used for creating additional OMOP JSON. A second Docker image will execute the Python script that queries the OMOP RDBMS and exports the OMOP JSON files