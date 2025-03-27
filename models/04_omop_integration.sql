-- OMOP Integration Schema
-- This schema adds support for mapping to OMOP CDM

-- OMOP observation mapping view
CREATE VIEW omop_observations AS
SELECT 
    p.person_id,
    m.concept_id as observation_concept_id,
    r.created_at as observation_date,
    r.response_value as value_as_string,
    m2.concept_id as value_as_concept_id,
    m.domain_id,
    m.vocabulary_id,
    'Patient reported' as observation_type_concept_id,
    m.concept_id as observation_source_concept_id,
    m.vocabulary_id || ':' || m.concept_id as observation_source_value
FROM question_response_concept_mappings m
JOIN responses r ON m.response_id = r.response_id
JOIN questions q ON m.question_id = q.question_id
JOIN persons p ON r.person_id = p.person_id
LEFT JOIN clinical_concept_mappings m2 ON r.response_id = m2.response_id
WHERE m2.mapped_type = 'response';

-- OMOP concept mapping table
CREATE TABLE omop_concept_mappings (
    mapping_id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_concept_id INTEGER NOT NULL,
    source_vocabulary_id TEXT NOT NULL,
    target_concept_id INTEGER NOT NULL,
    target_vocabulary_id TEXT NOT NULL,
    mapping_type TEXT NOT NULL CHECK (
        mapping_type IN ('question', 'response', 'pair')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_omop_mappings_source ON omop_concept_mappings(source_concept_id, source_vocabulary_id);
CREATE INDEX idx_omop_mappings_target ON omop_concept_mappings(target_concept_id, target_vocabulary_id);

-- Trigger to update timestamp
CREATE TRIGGER update_omop_mapping_timestamp
AFTER UPDATE ON omop_concept_mappings
BEGIN
    UPDATE omop_concept_mappings
    SET updated_at = CURRENT_TIMESTAMP
    WHERE mapping_id = NEW.mapping_id;
END; 