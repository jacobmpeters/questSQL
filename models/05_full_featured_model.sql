-- QuestSQL Full-Featured Data Model
-- This schema combines all features from previous levels into a complete model
-- that supports all question types, concept mapping, and OMOP CDM integration.

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
    question_type TEXT NOT NULL,
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

-- Question Type Specific Tables
CREATE TABLE question_options (
    option_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    option_text TEXT NOT NULL,
    option_value TEXT,
    order_index INTEGER NOT NULL,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- Grid Questions (Normalized)
CREATE TABLE grid_questions (
    grid_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    grid_type TEXT NOT NULL CHECK (
        grid_type IN ('matrix', 'ranking', 'rating')
    ),
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

CREATE TABLE grid_rows (
    row_id INTEGER PRIMARY KEY,
    grid_id INTEGER NOT NULL,
    row_text TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    FOREIGN KEY (grid_id) REFERENCES grid_questions(grid_id)
);

CREATE TABLE grid_columns (
    column_id INTEGER PRIMARY KEY,
    grid_id INTEGER NOT NULL,
    column_text TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    FOREIGN KEY (grid_id) REFERENCES grid_questions(grid_id)
);

CREATE TABLE grid_responses (
    grid_response_id INTEGER PRIMARY KEY,
    grid_id INTEGER NOT NULL,
    row_id INTEGER NOT NULL,
    column_id INTEGER NOT NULL,
    response_text TEXT,
    response_value REAL,
    FOREIGN KEY (grid_id) REFERENCES grid_questions(grid_id),
    FOREIGN KEY (row_id) REFERENCES grid_rows(row_id),
    FOREIGN KEY (column_id) REFERENCES grid_columns(column_id)
);

-- Conditional Questions
CREATE TABLE conditional_questions (
    conditional_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    parent_question_id INTEGER NOT NULL,
    parent_response_value TEXT NOT NULL,
    display_order INTEGER NOT NULL,
    FOREIGN KEY (question_id) REFERENCES questions(question_id),
    FOREIGN KEY (parent_question_id) REFERENCES questions(question_id)
);

-- Concept Mapping
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

-- Validation and Constraints
CREATE TABLE validation_rules (
    rule_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    rule_type TEXT NOT NULL CHECK (
        rule_type IN ('range', 'enum', 'format', 'required', 'grid')
    ),
    rule_value TEXT NOT NULL,
    error_message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- OMOP CDM Integration
CREATE TABLE observation_periods (
    observation_period_id INTEGER PRIMARY KEY,
    person_id INTEGER NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    period_type TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE visits (
    visit_id INTEGER PRIMARY KEY,
    person_id INTEGER NOT NULL,
    visit_start_date DATETIME NOT NULL,
    visit_end_date DATETIME NOT NULL,
    visit_type TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE visit_responses (
    visit_response_id INTEGER PRIMARY KEY,
    visit_id INTEGER NOT NULL,
    response_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (visit_id) REFERENCES visits(visit_id),
    FOREIGN KEY (response_id) REFERENCES responses(response_id)
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
CREATE INDEX idx_question_options_question ON question_options(question_id);
CREATE INDEX idx_grid_questions_question ON grid_questions(question_id);
CREATE INDEX idx_grid_rows_grid ON grid_rows(grid_id);
CREATE INDEX idx_grid_columns_grid ON grid_columns(grid_id);
CREATE INDEX idx_grid_responses_grid ON grid_responses(grid_id);
CREATE INDEX idx_grid_responses_row ON grid_responses(row_id);
CREATE INDEX idx_grid_responses_column ON grid_responses(column_id);
CREATE INDEX idx_conditional_questions_parent ON conditional_questions(parent_question_id);
CREATE INDEX idx_concept_mappings_question ON question_response_concept_mappings(question_id);
CREATE INDEX idx_concept_mappings_response ON question_response_concept_mappings(response_id);
CREATE INDEX idx_validation_rules_question ON validation_rules(question_id);
CREATE INDEX idx_observation_periods_person ON observation_periods(person_id);
CREATE INDEX idx_visits_person ON visits(person_id);
CREATE INDEX idx_visit_responses_visit ON visit_responses(visit_id);
CREATE INDEX idx_visit_responses_response ON visit_responses(response_id);

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
    m1.concept_id as response_concept_id,
    m2.concept_id as question_concept_id
FROM questionnaires q
JOIN questions qq ON q.questionnaire_id = qq.questionnaire_id
LEFT JOIN responses r ON qq.question_id = r.question_id
LEFT JOIN question_response_concept_mappings m1 ON r.response_id = m1.response_id
LEFT JOIN question_response_concept_mappings m2 ON qq.question_id = m2.question_id;

CREATE VIEW grid_responses_view AS
SELECT 
    gq.question_id,
    gr.row_text,
    gc.column_text,
    gres.response_text,
    gres.response_value
FROM grid_questions gq
JOIN grid_rows gr ON gq.grid_id = gr.grid_id
JOIN grid_columns gc ON gq.grid_id = gc.grid_id
LEFT JOIN grid_responses gres ON gq.grid_id = gres.grid_id 
    AND gr.row_id = gres.row_id 
    AND gc.column_id = gres.column_id;

CREATE VIEW omop_observations AS
SELECT 
    p.person_id,
    m.concept_id as observation_concept_id,
    r.response_date as observation_date,
    r.response_text as value_as_string,
    r.response_value as value_as_number,
    m2.concept_id as value_as_concept_id,
    m.domain_id,
    m.vocabulary_id,
    v.visit_id,
    v.visit_type,
    op.observation_period_id,
    op.period_type
FROM question_response_concept_mappings m
JOIN responses r ON m.response_id = r.response_id
JOIN questions q ON m.question_id = q.question_id
JOIN persons p ON r.person_id = p.person_id
LEFT JOIN question_response_concept_mappings m2 ON r.response_id = m2.response_id
LEFT JOIN visit_responses vr ON r.response_id = vr.response_id
LEFT JOIN visits v ON vr.visit_id = v.visit_id
LEFT JOIN observation_periods op ON p.person_id = op.person_id
WHERE r.response_date BETWEEN op.start_date AND op.end_date;

-- Example Usage
-- Create a questionnaire
INSERT INTO questionnaires (title, version, description)
VALUES ('OMOP Health Assessment', '1.0', 'Health assessment with OMOP CDM integration');

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

-- Create an observation period
INSERT INTO observation_periods (
    person_id,
    start_date,
    end_date,
    period_type
) VALUES (
    1,  -- person_id
    CURRENT_DATE,
    date(CURRENT_DATE, '+1 year'),
    'study'
);

-- Create a visit
INSERT INTO visits (
    person_id,
    visit_start_date,
    visit_end_date,
    visit_type
) VALUES (
    1,  -- person_id
    CURRENT_TIMESTAMP,
    datetime(CURRENT_TIMESTAMP, '+1 hour'),
    'ambulatory'
);

-- Get the visit_id
SELECT last_insert_rowid() as visit_id;

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

-- Link response to visit
INSERT INTO visit_responses (visit_id, response_id)
VALUES (
    1,  -- visit_id
    1   -- response_id
);

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

-- Example of creating a grid question
INSERT INTO questions (questionnaire_id, question_text, question_type, required, order_index)
VALUES (
    1,  -- questionnaire_id
    'Rate your symptoms over the past week',
    'grid',
    1,  -- required
    2
);

-- Get the question_id
SELECT last_insert_rowid() as question_id;

-- Create grid structure
INSERT INTO grid_questions (question_id, grid_type)
VALUES (2, 'rating');

-- Get the grid_id
SELECT last_insert_rowid() as grid_id;

-- Add grid rows
INSERT INTO grid_rows (grid_id, row_text, order_index)
VALUES 
    (1, 'Headache', 1),
    (1, 'Fatigue', 2),
    (1, 'Nausea', 3);

-- Add grid columns
INSERT INTO grid_columns (grid_id, column_text, order_index)
VALUES 
    (1, 'Never', 1),
    (1, 'Sometimes', 2),
    (1, 'Often', 3),
    (1, 'Always', 4);

-- Add grid responses
INSERT INTO grid_responses (grid_id, row_id, column_id, response_value)
VALUES 
    (1, 1, 2, 1),  -- Headache: Sometimes
    (1, 2, 3, 2),  -- Fatigue: Often
    (1, 3, 1, 0);  -- Nausea: Never 