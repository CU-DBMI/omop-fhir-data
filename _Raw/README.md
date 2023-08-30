## To create the synthea CSV files:

At {GIT_ROOT}
    
* `git clone https://github.com/synthetichealth/synthea`
* `git checkout -b v3.0.0` (must use Version/Release 3.0.0)
* `./run_synthea -s 12345 -p 100 --exporter.csv.export=true --exporter.fhir.export=false --exporter.ccd.export=false`


Synthea files are in ${GIT_ROOT}/synthea/output/csv
