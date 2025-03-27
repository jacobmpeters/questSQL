-- Question-Response Pair Mapping Schema
-- This schema adds support for mapping complete clinical observations through question-response pairs

-- Question-response pair mapping
CREATE TABLE question_response_concept_mappings (
    mapping_id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER REFERENCES questions(question_id),
    response_id INTEGER REFERENCES responses(response_id),
    concept_id INTEGER NOT NULL,
    vocabulary_id TEXT NOT NULL,
    domain_id TEXT NOT NULL CHECK (
        domain_id IN ('Condition', 'Measurement', 'Drug', 'Observation')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Ensure we have both question and response
    CONSTRAINT valid_pair CHECK (
        question_id IS NOT NULL AND response_id IS NOT NULL
    )
);

-- Indexes for performance
CREATE INDEX idx_pair_mappings_question ON question_response_concept_mappings(question_id);
CREATE INDEX idx_pair_mappings_response ON question_response_concept_mappings(response_id);
CREATE INDEX idx_pair_mappings_concept ON question_response_concept_mappings(concept_id);
CREATE INDEX idx_pair_mappings_domain ON question_response_concept_mappings(domain_id);

-- Trigger to update timestamp
CREATE TRIGGER update_pair_mapping_timestamp
AFTER UPDATE ON question_response_concept_mappings
BEGIN
    UPDATE question_response_concept_mappings
    SET updated_at = CURRENT_TIMESTAMP
    WHERE mapping_id = NEW.mapping_id;
END; 