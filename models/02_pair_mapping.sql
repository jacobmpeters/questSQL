-- QuestSQL Question-Response Pair Mapping Model
-- This schema extends the basic model to support mapping complete clinical observations
-- through question-response pairs.

-- Core Tables (from basic model)
CREATE TABLE questionnaires (
    questionnaire_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    version TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'draft',
    UNIQUE(title, version)
);

CREATE TABLE questions (
    question_id INTEGER PRIMARY KEY,
    questionnaire_id INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (
        question_type IN ('true_false', 'multiple_choice', 'text', 'numeric')
    ),
    required INTEGER DEFAULT 0,
    order_index INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(questionnaire_id)
);

CREATE TABLE responses (
    response_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    response_text TEXT,
    response_value REAL,
    response_date DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- Enhanced Concept Mapping
CREATE TABLE question_response_concept_mappings (
    mapping_id INTEGER PRIMARY KEY,
    question_id INTEGER,
    response_id INTEGER,
    concept_id INTEGER NOT NULL,
    vocabulary_id TEXT NOT NULL,
    domain_id TEXT NOT NULL CHECK (
        domain_id IN ('Condition', 'Measurement', 'Drug', 'Observation')
    ),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_mapping CHECK (
        (question_id IS NOT NULL AND response_id IS NULL) OR
        (question_id IS NULL AND response_id IS NOT NULL) OR
        (question_id IS NOT NULL AND response_id IS NOT NULL)
    ),
    FOREIGN KEY (question_id) REFERENCES questions(question_id),
    FOREIGN KEY (response_id) REFERENCES responses(response_id),
    FOREIGN KEY (concept_id) REFERENCES concept(concept_id)
);

-- Question-Response Pair Validation
CREATE TABLE pair_validation_rules (
    rule_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    response_value REAL,
    validation_type TEXT NOT NULL CHECK (
        validation_type IN ('range', 'enum', 'format')
    ),
    validation_value TEXT NOT NULL,
    error_message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- Triggers for Data Integrity
CREATE TRIGGER update_questionnaire_timestamp
    BEFORE UPDATE ON questionnaires
    BEGIN
        UPDATE questionnaires 
        SET updated_at = CURRENT_TIMESTAMP 
        WHERE questionnaire_id = NEW.questionnaire_id;
    END;

CREATE TRIGGER update_question_timestamp
    BEFORE UPDATE ON questions
    BEGIN
        UPDATE questions 
        SET updated_at = CURRENT_TIMESTAMP 
        WHERE question_id = NEW.question_id;
    END;

CREATE TRIGGER update_concept_mapping_timestamp
    BEFORE UPDATE ON question_response_concept_mappings
    BEGIN
        UPDATE question_response_concept_mappings 
        SET updated_at = CURRENT_TIMESTAMP 
        WHERE mapping_id = NEW.mapping_id;
    END;

-- Indexes for Performance
CREATE INDEX idx_questions_questionnaire ON questions(questionnaire_id);
CREATE INDEX idx_responses_question ON responses(question_id);
CREATE INDEX idx_concept_mappings_question ON question_response_concept_mappings(question_id);
CREATE INDEX idx_concept_mappings_response ON question_response_concept_mappings(response_id);
CREATE INDEX idx_pair_validation_question ON pair_validation_rules(question_id);

-- Views for Common Queries
CREATE VIEW question_response_pairs AS
SELECT 
    q.questionnaire_id,
    q.title as questionnaire_title,
    qq.question_id,
    qq.question_text,
    qq.question_type,
    r.response_text,
    r.response_value,
    r.response_date,
    m1.concept_id as response_concept_id,
    m2.concept_id as question_concept_id,
    m3.concept_id as pair_concept_id
FROM questionnaires q
JOIN questions qq ON q.questionnaire_id = qq.questionnaire_id
LEFT JOIN responses r ON qq.question_id = r.question_id
LEFT JOIN question_response_concept_mappings m1 ON r.response_id = m1.response_id
LEFT JOIN question_response_concept_mappings m2 ON qq.question_id = m2.question_id
LEFT JOIN question_response_concept_mappings m3 ON qq.question_id = m3.question_id AND r.response_id = m3.response_id;

-- Example Usage
-- Create a questionnaire
INSERT INTO questionnaires (title, version, description)
VALUES ('Enhanced Health Assessment', '1.0', 'Health assessment with pair mapping');

-- Get the questionnaire_id
SELECT last_insert_rowid() as questionnaire_id;

-- Add a question
INSERT INTO questions (questionnaire_id, question_text, question_type, required, order_index)
VALUES (
    1,  -- questionnaire_id
    'What is your blood pressure?',
    'numeric',
    1,  -- required
    1
);

-- Get the question_id
SELECT last_insert_rowid() as question_id;

-- Add validation rule
INSERT INTO pair_validation_rules (
    question_id,
    response_value,
    validation_type,
    validation_value,
    error_message
) VALUES (
    1,  -- question_id
    120,  -- response_value
    'range',
    '90-140',
    'Blood pressure should be between 90 and 140'
);

-- Map the question to a concept
INSERT INTO question_response_concept_mappings (
    question_id,
    concept_id,
    vocabulary_id,
    domain_id
) VALUES (
    1,  -- question_id
    3004249,  -- OMOP concept_id for blood pressure
    'SNOMED',
    'Measurement'
);

-- Add a response
INSERT INTO responses (question_id, response_text, response_value, response_date)
VALUES (
    1,  -- question_id
    '120/80',
    120,
    CURRENT_TIMESTAMP
);

-- Get the response_id
SELECT last_insert_rowid() as response_id;

-- Map the response to a concept
INSERT INTO question_response_concept_mappings (
    response_id,
    concept_id,
    vocabulary_id,
    domain_id
) VALUES (
    1,  -- response_id
    4171373,  -- OMOP concept_id for normal blood pressure
    'SNOMED',
    'Measurement'
);

-- Map the question-response pair to a concept
INSERT INTO question_response_concept_mappings (
    question_id,
    response_id,
    concept_id,
    vocabulary_id,
    domain_id
) VALUES (
    1,  -- question_id
    1,  -- response_id
    4171373,  -- OMOP concept_id for normal blood pressure
    'SNOMED',
    'Measurement'
); 