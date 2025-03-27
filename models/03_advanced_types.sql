-- QuestSQL Advanced Question Types Model
-- This schema extends the pair mapping model to support complex question types
-- including grid questions and conditional logic.

-- Core Tables (from pair mapping model)
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
        question_type IN ('true_false', 'multiple_choice', 'text', 'numeric', 'grid', 'conditional')
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

-- Question Type Specific Tables
CREATE TABLE question_options (
    option_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    option_text TEXT NOT NULL,
    option_value TEXT,
    order_index INTEGER NOT NULL,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

CREATE TABLE grid_questions (
    grid_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    grid_type TEXT NOT NULL CHECK (
        grid_type IN ('matrix', 'ranking', 'rating')
    ),
    rows TEXT,  -- JSON stored as TEXT
    columns TEXT,  -- JSON stored as TEXT
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

CREATE TABLE grid_responses (
    grid_response_id INTEGER PRIMARY KEY,
    grid_id INTEGER NOT NULL,
    row_index INTEGER NOT NULL,
    column_index INTEGER NOT NULL,
    response_text TEXT,
    response_value REAL,
    FOREIGN KEY (grid_id) REFERENCES grid_questions(grid_id)
);

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
CREATE INDEX idx_grid_responses_grid ON grid_responses(grid_id);
CREATE INDEX idx_conditional_questions_parent ON conditional_questions(parent_question_id);
CREATE INDEX idx_concept_mappings_question ON question_response_concept_mappings(question_id);
CREATE INDEX idx_concept_mappings_response ON question_response_concept_mappings(response_id);
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
    m1.concept_id as response_concept_id,
    m2.concept_id as question_concept_id
FROM questionnaires q
JOIN questions qq ON q.questionnaire_id = qq.questionnaire_id
LEFT JOIN responses r ON qq.question_id = r.question_id
LEFT JOIN question_response_concept_mappings m1 ON r.response_id = m1.response_id
LEFT JOIN question_response_concept_mappings m2 ON qq.question_id = m2.question_id;

-- Example Usage
-- Create a questionnaire
INSERT INTO questionnaires (title, version, description)
VALUES ('Advanced Health Assessment', '1.0', 'Health assessment with complex question types');

-- Get the questionnaire_id
SELECT last_insert_rowid() as questionnaire_id;

-- Add a grid question
INSERT INTO questions (questionnaire_id, question_text, question_type, required, order_index)
VALUES (
    1,  -- questionnaire_id
    'Rate your symptoms over the past week',
    'grid',
    1,  -- required
    1
);

-- Get the question_id
SELECT last_insert_rowid() as question_id;

-- Create grid structure
INSERT INTO grid_questions (question_id, grid_type, rows, columns)
VALUES (
    1,  -- question_id
    'rating',
    '["Headache", "Fatigue", "Nausea"]',  -- JSON as TEXT
    '["Never", "Sometimes", "Often", "Always"]'  -- JSON as TEXT
);

-- Add grid responses
INSERT INTO grid_responses (grid_id, row_index, column_index, response_value)
VALUES 
    (1, 0, 1, 1),  -- Headache: Sometimes
    (1, 1, 2, 2),  -- Fatigue: Often
    (1, 2, 0, 0);  -- Nausea: Never

-- Map grid question to concept
INSERT INTO question_response_concept_mappings (
    question_id,
    concept_id,
    vocabulary_id,
    domain_id
) VALUES (
    1,  -- question_id
    3004249,  -- OMOP concept_id for symptoms
    'SNOMED',
    'Observation'
);

-- Add a conditional question
INSERT INTO questions (questionnaire_id, question_text, question_type, required, order_index)
VALUES (
    1,  -- questionnaire_id
    'If you have headaches, how severe are they?',
    'conditional',
    0,  -- not required
    2
);

-- Get the question_id
SELECT last_insert_rowid() as question_id;

-- Set up conditional logic
INSERT INTO conditional_questions (
    question_id,
    parent_question_id,
    parent_response_value,
    display_order
) VALUES (
    2,  -- question_id
    1,  -- parent_question_id
    'Often',  -- parent_response_value
    1
);

-- Add validation rule
INSERT INTO validation_rules (
    question_id,
    rule_type,
    rule_value,
    error_message
) VALUES (
    1,  -- question_id
    'grid',
    '{"min_responses": 3}',  -- JSON as TEXT
    'Please rate all symptoms'
); 