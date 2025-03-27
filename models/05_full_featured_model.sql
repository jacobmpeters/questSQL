-- QuestSQL Full-Featured Data Model
-- This schema combines all features from previous levels into a complete model
-- that supports all question types, concept mapping, and OMOP CDM integration.

-- Core Tables
CREATE TABLE questionnaires (
    questionnaire_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    version TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'draft',
    UNIQUE(title, version)
);

CREATE TABLE questions (
    question_id INTEGER PRIMARY KEY,
    questionnaire_id INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL,
    required BOOLEAN DEFAULT false,
    order_index INTEGER NOT NULL,
    concept_id INTEGER,  -- Maps to OMOP concept
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(questionnaire_id),
    FOREIGN KEY (concept_id) REFERENCES concept(concept_id)
);

CREATE TABLE responses (
    response_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    response_text TEXT,
    response_value NUMERIC,
    response_date TIMESTAMP,
    concept_id INTEGER,  -- Maps to OMOP concept
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(question_id),
    FOREIGN KEY (concept_id) REFERENCES concept(concept_id)
);

-- Question Type Specific Tables
CREATE TABLE question_options (
    option_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    option_text TEXT NOT NULL,
    option_value TEXT,
    concept_id INTEGER,  -- Maps to OMOP concept
    order_index INTEGER NOT NULL,
    FOREIGN KEY (question_id) REFERENCES questions(question_id),
    FOREIGN KEY (concept_id) REFERENCES concept(concept_id)
);

CREATE TABLE grid_questions (
    grid_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    grid_type TEXT NOT NULL,
    rows JSONB,
    columns JSONB,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

CREATE TABLE grid_responses (
    grid_response_id INTEGER PRIMARY KEY,
    grid_id INTEGER NOT NULL,
    row_index INTEGER NOT NULL,
    column_index INTEGER NOT NULL,
    response_text TEXT,
    response_value NUMERIC,
    concept_id INTEGER,  -- Maps to OMOP concept
    FOREIGN KEY (grid_id) REFERENCES grid_questions(grid_id),
    FOREIGN KEY (concept_id) REFERENCES concept(concept_id)
);

-- Validation and Constraints
CREATE TABLE validation_rules (
    rule_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    rule_type TEXT NOT NULL,
    rule_value TEXT,
    error_message TEXT,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- OMOP CDM Integration
CREATE TABLE observation_periods (
    observation_period_id INTEGER PRIMARY KEY,
    person_id INTEGER NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    period_type TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE visits (
    visit_id INTEGER PRIMARY KEY,
    person_id INTEGER NOT NULL,
    visit_start_date TIMESTAMP NOT NULL,
    visit_end_date TIMESTAMP NOT NULL,
    visit_type TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Triggers for Data Integrity
CREATE TRIGGER update_questionnaire_timestamp
    BEFORE UPDATE ON questionnaires
    FOR EACH ROW
    BEGIN
        SET NEW.updated_at = CURRENT_TIMESTAMP;
    END;

CREATE TRIGGER update_question_timestamp
    BEFORE UPDATE ON questions
    FOR EACH ROW
    BEGIN
        SET NEW.updated_at = CURRENT_TIMESTAMP;
    END;

-- Indexes for Performance
CREATE INDEX idx_questions_questionnaire ON questions(questionnaire_id);
CREATE INDEX idx_responses_question ON responses(question_id);
CREATE INDEX idx_question_options_question ON question_options(question_id);
CREATE INDEX idx_grid_questions_question ON grid_questions(question_id);
CREATE INDEX idx_grid_responses_grid ON grid_responses(grid_id);
CREATE INDEX idx_validation_rules_question ON validation_rules(question_id);

-- Views for Common Queries
CREATE VIEW questionnaire_responses AS
SELECT 
    q.questionnaire_id,
    q.title as questionnaire_title,
    qq.question_id,
    qq.question_text,
    qq.question_type,
    r.response_text,
    r.response_value,
    r.response_date,
    r.concept_id as response_concept_id,
    qq.concept_id as question_concept_id
FROM questionnaires q
JOIN questions qq ON q.questionnaire_id = qq.questionnaire_id
LEFT JOIN responses r ON qq.question_id = r.question_id;

-- Example Usage
-- Create a questionnaire
INSERT INTO questionnaires (title, version, description)
VALUES ('Health Assessment', '1.0', 'Comprehensive health assessment questionnaire')
RETURNING questionnaire_id;

-- Add a question with concept mapping
INSERT INTO questions (questionnaire_id, question_text, question_type, required, order_index, concept_id)
VALUES (
    1,  -- questionnaire_id
    'What is your blood pressure?',
    'numeric',
    true,
    1,
    3004249  -- OMOP concept_id for blood pressure
)
RETURNING question_id;

-- Add a response with concept mapping
INSERT INTO responses (question_id, response_text, response_value, response_date, concept_id)
VALUES (
    1,  -- question_id
    '120/80',
    120,
    CURRENT_TIMESTAMP,
    4171373  -- OMOP concept_id for normal blood pressure
); 