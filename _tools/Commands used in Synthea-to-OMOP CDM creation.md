# Commands used in Synthea-to-OMOP CDM creation

This document contains the commands and issues while creating a Synthea to OMOP CDM Postgres pipeline. It is **NOT** a generalized set of commands. It captures only the various twists and turns I encountered in establishing a pipeline using Google's Cloud GCE VM and Postgres CloudSQL.

As mentioned elsewhere, my original intent was to create Docker images for all of these steps. But the OHDSI R script that reads in the vary large OMOP vocabularies would consistently crash Docker because it ran out of memory on my 32GB Macbook Pro (yes, I did adjust the memory settings for Docker but it still ran out). So I moved to a large-memory GCE on Google. I made no attempt to optimize anything. It was a _get this done ASAP_ process. YMMV.......

1. Log into Google Cloud with the appropriate credentials and permiions using `gcloud auth login`

2. Create new GCE and CloudSQL instances.
  - Used a "sandbox" project
  - GCE: Name synthea3; Machine type n2-standard-16; Architecture: x86/64; Boot disk 100GB SSD; no encryption
  - CloudSQL: Postgres 12.14; 4 vCPUs, 16 GB memory, 100 GB SSD storage; Private IP address only; set inistial Postgres password to synthea

3. Log into GCE using local terminal: `gcloud compute ssh --zone "us-central1-a" "synthea3" --project "sandbox"`

4. Create the "raw" Synthea CSV files:
  - Download from github `https://github.com/synthetichealth/synthea`
  - Must use Version/Release 3.0.0 code for OHDSI Synthea ETL code: `git checkout -b v3.0.0`
  - Run Synthea: `./run_synthea -s 12345 -p 10 --exporter.csv.export=true --exporter.fhir.export=false --exporter.ccd.export=false --expoerter.baseDirectory="./output10/` We use the value in the -p parameter in the output folder name. In this example -p 10 so we put CSV output into the folder named output10.

5. Install the PG tools on the GCE: `sudo apt update; sudo apt upgrade; sudo apt-get install postgresql-cleint` Set up the PG database using psql using the **correct private IP** (10.10.10.10 is fake): `psql -h 10.10.10.10  -U postgres`  
`create database synthea;`   
`create schema native100;`  
`create schema synthea100;`  
NOTE Native and Synthea schema names reflect the same naming convention used in the Synthea raw output. In this example, we are creating a 100 patient data set. So we name the schemas native100 and synthea100 for our own sanity.

6. If you need to drop schemas: `drop scehma <schema_name> cascade;`

7. Set up R in GCE: If GCE image is new, you need to install the follwoing packages to enable the R devtools package to work:  
`sudo apt update`  
`sudo apt upgrade`  
`sudo apt-get install build-essential libcurl4-gnutls-dev libxml2-dev libssl-dev`  
`sudo apt-get install libcurl4-openssl-dev libbz2-dev liblzma-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev`  
`sudo apt-get install default-jdk default-jre rJava openssh-server`  
`sudo apt-get install r-base`  

8. Set up the OMOP vocabulary files in GCE.  
Create a vocabulary folder and move 10 Athena raw downloads (includes CPT4). I'm using GCS buckets and downloading from there into a current directory (.).  
`gsutil -m cp   "gs://omop_vocab_2023_07_15/CONCEPT.csv" \`  
` "gs://omop_vocab_2023_07_15/CONCEPT_ANCESTOR.csv"  \`  
` "gs://omop_vocab_2023_07_15/CONCEPT_CLASS.csv" \`  
` "gs://omop_vocab_2023_07_15/CONCEPT_CPT4.csv"  \`  
` "gs://omop_vocab_2023_07_15/CONCEPT_RELATIONSHIP.csv" \`  
` "gs://omop_vocab_2023_07_15/CONCEPT_SYNONYM.csv"  \`  
` "gs://omop_vocab_2023_07_15/DOMAIN.csv"  \`
` "gs://omop_vocab_2023_07_15/DRUG_STRENGTH.csv"  \`
` "gs://omop_vocab_2023_07_15/RELATIONSHIP.csv" \`
` "gs://omop_vocab_2023_07_15/VOCABULARY.csv"  \`  
` .`  
Need to get rid of difficult characters: `find . -type f -exec sed -i.bak 's/["\\]//g' {} \;`

9. Download OHDSI ETL_Synthea repo: `git clone https://github.com/OHDSI/ETL-Synthea`  
Run the R code (in R shell) in two stages:  
  - Stage 1: (the Synthea steps):
  - `devtools::install_github("OHDSI/ETL-Synthea")`  
  - `cd <- DatabaseConnector::createConnectionDetails(`  
  `dbms     = "postgresql",`  
  `server   = "10.10.10.10/synthea",`  
  `user     = "postgres",`   
  `password = "synthea",`   
  `port     = 5432,`   
  `#  pathToDriver = "d:/drivers"`  
  `)`  
    
  `cdmSchema      <- "synthea10"`  
   `cdmVersion     <- "5.3"`  
   `syntheaVersion <- "3.0.0"`  
   `syntheaSchema  <- "native10"`  
   `syntheaFileLoc <- "/home/michael_kahn_healthdatacompass_o/git/synthea3.0.0/output10/csv"`  
   `vocabFileLoc   <- "/home/michael_kahn_healthdatacompass_o/git/OMOP/vocabs"`  
   
   `ETLSyntheaBuilder::CreateCDMTables(connectionDetails = cd, cdmSchema = cdmSchema, cdmVersion = cdmVersion)`                                       
   `ETLSyntheaBuilder::CreateSyntheaTables(connectionDetails = cd, syntheaSchema = syntheaSchema, syntheaVersion = syntheaVersion)`                                        
   `ETLSyntheaBuilder::LoadSyntheaTables(connectionDetails = cd, syntheaSchema = syntheaSchema, syntheaFileLoc = syntheaFileLoc)`  

10. Fix issue with Synthea device.udi being too long for OMOP.devices.udi field.  In GCE: `psql -h 10.10.10.10 -U postgres update native10.devices set udi = substring(udi from 1 for 49);`

11. Run ETL_Synthea R Stage 2 (the OMOP steps)  
  `ETLSyntheaBuilder::LoadVocabFromCsv(connectionDetails = cd, cdmSchema = cdmSchema, vocabFileLoc = vocabFileLoc)`                                    
   `ETLSyntheaBuilder::LoadEventTables(connectionDetails = cd, cdmSchema = cdmSchema, syntheaSchema = syntheaSchema, cdmVersion = cdmVersion, syntheaVersion = syntheaVersion)`
   
12. To create a backup of the two schemas (native10; synthea10) PG database into file pgdump_synthea10.sql: `pg_dump -h 10.10.10.10 -U postgres -W -O -C -v -n native10 -n synthea10 -f pgdump_synthea10.sql synthea`

13.  To restore the pg_dump file on another PG server (e.g. 11.11.11.11): `psql -h 11.11.11.1 -U postgres -W synthea <./pgdump_synthea10.sql`

14. To download the pg_dump file from GCE (mgkahn-synthea3) to a local machine, execute on the LOCAL machine: `gcloud compute scp mgkahn-synthea3:~/pg_dumpfile_synthea3 .`  
To download to a bucket: `gsutil -m cp file1 file2 gs://bucket`

---
This text is incomplete:  
Set up GCE for the Python extraction steps:
 
1. Install python3 and pip3 on GCE: `sudo apt-get install python3-pip`  
2. Download the repo with the _tools directory: `git clone https://github.com/cu-dbmi/omop-fhir-data`  
3. Install miniconda: `mkdir -p ~/miniconda3`  
  `mkdir -p ~/miniconda3`  
  `wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh`  
  `bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3`  
  `rm -rf ~/miniconda3/miniconda.sh`  
  `~/miniconda3/bin/conda init bash`  
  `~/miniconda3/bin/conda init zsh`  
4. Configure conda environment:  
  `conda create --name mends`  
  `conda activate mends`  
  `python3 -m pip install db-api pandas  sqlalchemy pyarrow argparse psycopg2-binary google.cloud.storage google.cloud.bigquery pybigquery`  
**Better method**  
  `pip3 install -R requirements.txt`  
5. Script that runs the extract: `git/omop-fhir-data/_tools/omop-tools/bin/Extract_OMOP_json.sh`





