#!/usr/bin/env bash
#set -x
set -e
set -u
set -o pipefail
set -o noclobber
#shopt -s  nullglob

export HOME=/workdir
export SQL_DIR=${HOME}/sql/
export DB=postgresql
export DBARGS=synthea/synthea10
export LOCALDIR=${HOME}/omop_json/synthea
export CHUNKSIZE=10000
export NROWS=10000

cd /workdir
mkdir -p ${LOCALDIR}
rm -fr ${LOCALDIR}/*.json
echo "Generating condition_occurrence"
./generate-input.py --sqlfile ${SQL_DIR}/MENDS_queries_condition_occurrence.sql --database ${DB} --dbargs ${DBARGS} --localdir ${LOCALDIR} --chunksize ${CHUNKSIZE} --rows ${NROWS} 
echo "Generating drug_exposure"
./generate-input.py --sqlfile ${SQL_DIR}/MENDS_queries_drug_exposure_drug_strength.sql --database ${DB} --dbargs ${DBARGS} --localdir ${LOCALDIR} --chunksize ${CHUNKSIZE} --rows ${NROWS} 
echo "Generating measurement"
./generate-input.py --sqlfile ${SQL_DIR}/MENDS_queries_measurement.sql --database ${DB} --dbargs ${DBARGS} --localdir ${LOCALDIR} --chunksize ${CHUNKSIZE} --rows ${NROWS} 
echo "Generating observation_notsmoking"
./generate-input.py --sqlfile ${SQL_DIR}/MENDS_queries_observation_notsmoking.sql --database ${DB} --dbargs ${DBARGS} --localdir ${LOCALDIR} --chunksize ${CHUNKSIZE} --rows ${NROWS} 
echo "Generating payer_plan_period"
./generate-input.py --sqlfile ${SQL_DIR}/MENDS_queries_payer_plan_period.sql --database ${DB} --dbargs ${DBARGS} --localdir ${LOCALDIR} --chunksize ${CHUNKSIZE} --rows ${NROWS} 
echo "Generating person"
./generate-input.py --sqlfile ${SQL_DIR}/MENDS_queries_person_location.sql --database ${DB} --dbargs ${DBARGS} --localdir ${LOCALDIR} --chunksize ${CHUNKSIZE} --rows ${NROWS} 
#echo "Generating smoking"
# ./generate-input.py --sqlfile ${SQL_DIR}/MENDS_queries_smoking.sql --database ${DB} --dbargs ${DBARGS} --localdir ${LOCALDIR} --chunksize ${CHUNKSIZE} --rows ${NROWS} 
echo "Generating visit_occurrence"
./generate-input.py --sqlfile ${SQL_DIR}/MENDS_queries_visit_occurrence.sql --database ${DB} --dbargs ${DBARGS} --localdir ${LOCALDIR} --chunksize ${CHUNKSIZE} --rows ${NROWS} 
