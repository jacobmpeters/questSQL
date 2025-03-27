-- QuestSQL Basic Model
-- This schema provides the foundation for questionnaire development with basic question types
-- and simple concept mapping.

-- Core Tables
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
        question_type IN ('true_false', 'multiple_choice', 'text')
    ),
    required INTEGER DEFAULT 0,
    order_index INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
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

-- Basic Concept Mapping
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

-- Triggers for Data Integrity
CREATE TRIGGER update_questionnaire_timestamp
    BEFORE UPDATE ON questionnaires
    BEGIN
        UPDATE questionnaires 
        SET updated_at = CURRENT_TIMESTAMP 
        WHERE questionnaire_id = NEW.questionnaire_id;
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

-- Example Usage
-- Create a questionnaire
INSERT INTO questionnaires (title, version, description)
VALUES ('Basic Health Assessment', '1.0', 'Simple health assessment questionnaire');

-- Get the questionnaire_id
SELECT last_insert_rowid() as questionnaire_id;

-- Add a question
INSERT INTO questions (questionnaire_id, question_text, question_type, required, order_index)
VALUES (
    1,  -- questionnaire_id
    'Do you have high blood pressure?',
    'true_false',
    1,  -- required
    1
);

-- Get the question_id
SELECT last_insert_rowid() as question_id;

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
    'Yes',
    1,
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