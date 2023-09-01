# OMOP-FHIR DATA

# Overview
The repo holds OMOP JSON data sets that can be used to run the OMOP-to-FHIR pipeline available in the [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo. Using these data sets obviates the need for access to an instance of an OMOP CDM running on an RDBMS. Each folder represents a different data set. Folder names follow the same naming convention: Source-Method-Rows:

* Source: the original data source. Usually a public domain deidentified data resource. Currently only Synthea data sets have been created.
* Method: currently one of {random, cohort}. Random data sets do not maintain referential integrity but will always have a **fixed number of rows** per table. Cohort-based data sets maintain referential integrity and will have the **fixed number of patients**. However cohort-based queries  will not have a fixed number of rows in clinical data tables in order to maintain referential integrity within a patient's data. 
* Rows: The number of rows in a table. See above for difference between random and cohort queries.

An example is the folder: synthea-random-20. This folder has OMOP JSON data that was created using **Synthea**, using a **random** query, with each table having **exactly 20 rows** with no referential integrity between tables.

## Usage
The [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo contains a script that mounts one of the data folders from this repository as a submodule that is used as its input OMOP JSON to start the OMOP-to-FHIR conversion pipeline. See the README description in the [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo which describes how to alter the appropriate environment variable to mount a different data folder.

## The _tools folder
### Overall design

The data folders are the end-product of an earlier process that extracts OMOP JSON from an OMOP CDM V5.3 RDBMS. In the **_tools** folder, we provide tooling for creating the OMOP JSON files.

The figure below, a generalized version from our [technical publication](https://medrxiv.org/cgi/content/short/2023.08.09.23293900v1), shows the more complete data pipeline that includes generating OMOP CDMs and OMOP JSON files from public domain sources. Our work to date only uses the [Synthea](https://github.com/synthetichealth/synthea) synthetic patient data generation system. Only those parts highlighted in blue are implemented in this folder. The pipeline in green is implemented in the [MENDS-on-FHIR](https://github.com/cu-dbmi/mends-on-fhir) repo, which expects OMOP JSON to have been generated.


![High level processing flow](/_assets/images/MENDS-generalized.png)

This is a work in progress. It will have two steps:

1. Creating a **pre-populated Postgres OMOP CDM V5.3 Docker image** that contains one of the available data sets along with the OMOP vocabulary.
  - This step uses a **pg dump file** generated from a **VM-hosted** PG server.
  - As implemented by OHDSI, the ETL-Synthea R script requires a ton of memory when importing the very large OMOP vocabulary files. 
  - I was unable to allocate sufficient memory resources to a PG Docker image on my 32GB Macbook Pro to do this pipeline locally using only Docker. 
 
  - I have included the detailed steps that I used behind the scenes to create these pg dump files using Google's GCE and SQL services in the file named **Commands_Synthea-to-OMOP**.

2. The Python pipeline that extracts OMOP JSON from a pre-populated Postgres OMOP Docker container


