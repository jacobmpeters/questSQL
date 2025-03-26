-- Questionnaire Data Model Schema

-- Questionnaire metadata table
CREATE TABLE questionnaires (
    questionnaire_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    version TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Concepts table to store standardized medical concepts
CREATE TABLE concepts (
    concept_id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,  -- e.g., ICD-10, SNOMED, or custom codes
    name TEXT NOT NULL,
    description TEXT,
    concept_type TEXT,  -- e.g., 'diagnosis', 'symptom', 'medication'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Questions table
CREATE TABLE questions (
    question_id INTEGER PRIMARY KEY AUTOINCREMENT,
    questionnaire_id INTEGER NOT NULL,
    concept_id INTEGER,  -- Optional link to standardized concept
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL,  -- 'true_false', 'multiple_choice', 'select_all', 'grid', 'free_text', 'loop'
    is_required BOOLEAN DEFAULT FALSE,
    display_order INTEGER NOT NULL,
    parent_question_id INTEGER,  -- For nested questions (e.g., grid questions)
    loop_question_id INTEGER,    -- For loop questions, references the parent loop question
    loop_position INTEGER,       -- Position within the loop (for loop questions)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(questionnaire_id),
    FOREIGN KEY (concept_id) REFERENCES concepts(concept_id),
    FOREIGN KEY (parent_question_id) REFERENCES questions(question_id),
    FOREIGN KEY (loop_question_id) REFERENCES questions(question_id)
);

-- Question options for multiple choice, select-all, and grid questions
CREATE TABLE question_options (
    option_id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    option_text TEXT NOT NULL,
    option_value TEXT NOT NULL,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- Grid question columns (for grid questions)
CREATE TABLE grid_columns (
    column_id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    column_text TEXT NOT NULL,
    column_value TEXT NOT NULL,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- Skip logic conditions
CREATE TABLE skip_logic (
    skip_logic_id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    target_question_id INTEGER NOT NULL,
    condition_type TEXT NOT NULL,  -- 'equals', 'not_equals', 'contains', 'greater_than', etc.
    condition_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(question_id),
    FOREIGN KEY (target_question_id) REFERENCES questions(question_id)
);

-- Responses table
CREATE TABLE responses (
    response_id INTEGER PRIMARY KEY AUTOINCREMENT,
    questionnaire_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    response_value TEXT NOT NULL,
    loop_instance INTEGER,  -- For loop questions, indicates which instance this response belongs to
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(questionnaire_id),
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- Indexes for better query performance
CREATE INDEX idx_questions_questionnaire ON questions(questionnaire_id);
CREATE INDEX idx_questions_parent ON questions(parent_question_id);
CREATE INDEX idx_questions_loop ON questions(loop_question_id);
CREATE INDEX idx_responses_questionnaire ON responses(questionnaire_id);
CREATE INDEX idx_responses_question ON responses(question_id);
CREATE INDEX idx_skip_logic_question ON skip_logic(question_id);
CREATE INDEX idx_skip_logic_target ON skip_logic(target_question_id); 