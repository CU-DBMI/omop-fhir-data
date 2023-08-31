-- incorrect value for condition_type_concept_id
update condition_occurrence
set condition_type_concept_id = 32020
where condition_type_concept_id = 38000175;

