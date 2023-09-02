# OMOP-FHIR DATA

# Overview
This repo holds OMOP JSON data sets that can be used to run the OMOP-to-FHIR pipeline available in the [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo. Using these data sets obviates the need for access to an instance of an OMOP CDM running on an RDBMS. Each folder represents a different data set. Folder names follow the same naming convention: Source-Method-Rows:

* Source: the original data source. Usually a public domain deidentified data resource. Currently only Synthea data sets have been created.
* Method: currently one of {random, cohort}. Random data sets do not maintain referential integrity but will always have a **fixed number of rows** per table. Cohort-based data sets maintain referential integrity and will have the **fixed number of patients**. However cohort-based queries  will not have a fixed number of rows in clinical data tables in order to maintain referential integrity within a patient's data. 
* Rows: The number of rows in a table. See above for difference between random and cohort queries.

An example is the folder synthea-random-20. This folder has OMOP JSON data that was created using **Synthea**, using a **random** query, with each table having **exactly 20 rows** with no referential integrity between tables. The folder synthea-cohort-10 has OMOP JSON data created using Synthea based on a 10-person cohort with referential integriy.

## Usage
The [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo contains a script that mounts one of the data folders from this repository as a submodule that is used as its input OMOP JSON to start the OMOP-to-FHIR conversion pipeline. See the README description in the [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo which describes how to alter the appropriate environment variable to mount a different data folder.

## The tools folder
The data folders are the end-product of an earlier process that extracts OMOP JSON from an OMOP CDM V5.3 RDBMS. In the **tools** folder, we provide tooling for creating the OMOP JSON files.

The figure below, a generalized version from our [technical publication](https://medrxiv.org/cgi/content/short/2023.08.09.23293900v1). It shows a more complete data pipeline that includes generating OMOP CDMs and OMOP JSON files from public domain sources (blue boxes). Our public-facing work to date only uses the [Synthea](https://github.com/synthetichealth/synthea) synthetic patient data generation system. Only those parts highlighted in blue are implemented in this folder. The pipeline in green is implemented in the [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo, which expects OMOP JSON created here to have been generated.

![High level processing flow](/_assets/images/MENDS-generalized.png)

This README is a work in progress. We provide detailed steps in the file 'Commands\_Synthea\_to\_OMOP.md':

1. We followed the instructions on the [Synthea](https://github.com/synthetichealth/synthea) repo to generate CSV files with the desired population (using the `-p` argument. We used the Synthea3.0.0 tagged code rather than HEAD as needed by the OHDSI ETL tool.

2. We followed the instructions on the [OHDSI ETL-Synthea](https://github.com/OHDSI/ETL-Synthea) R tool to populate a Postgres database.
    - There is an error in the ETL-Synthea code that is fixed in the 'fixes.sql' script. A pull request has been submitted to the OHDSI ETL-Synthea repo.

3. We performed `pg_dump` to extract the Postgres database with the OMOP terminology and the ETL'd Synthea data.

    **NOTE: Steps 1-3 were performed using a bare-metal Postgres RDBMS. The OHDSI ETL-Synthea R tool reads large vocabulary files into memory before inserting into the database. My laptop did not have sufficient memory to perform this step no matter how much memory I allocated to the Docker Desktop application.**

4. In this directory, we provide the Dockerfile that consumes `pg_dump` files created in the previous step to create a Postgres Docker image prepopulated with the OMOP vocabularies and the ETL'd Synthea data.

5. In this directory, we provde a Docker image of the Python-based extract tool that queries the Docker Postgres DB and creates the OMOP JSON files used by the [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) pipeline.

6. In this directory, we provide a script/docker compose YML file that launches one of the pre-populated Postgres images and the Python extract image that performs the actual OMOP JSON extraction.




