-- Basic Model Schema
-- This schema represents the foundation of QuestSQL with core tables and basic concept mapping

-- Core tables
CREATE TABLE questionnaires (
    questionnaire_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE questions (
    question_id INTEGER PRIMARY KEY AUTOINCREMENT,
    questionnaire_id INTEGER REFERENCES questionnaires(questionnaire_id),
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (
        question_type IN ('true_false', 'multiple_choice', 'text')
    ),
    is_required BOOLEAN DEFAULT false,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE responses (
    response_id INTEGER PRIMARY KEY AUTOINCREMENT,
    questionnaire_id INTEGER REFERENCES questionnaires(questionnaire_id),
    question_id INTEGER REFERENCES questions(question_id),
    response_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE question_options (
    option_id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER REFERENCES questions(question_id),
    option_text TEXT NOT NULL,
    option_value TEXT NOT NULL,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Basic concept mapping
CREATE TABLE clinical_concept_mappings (
    mapping_id INTEGER PRIMARY KEY AUTOINCREMENT,
    mapped_type TEXT NOT NULL CHECK (mapped_type IN ('question', 'response')),
    question_id INTEGER REFERENCES questions(question_id),
    response_id INTEGER REFERENCES responses(response_id),
    concept_id INTEGER NOT NULL,
    vocabulary_id TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_questions_questionnaire ON questions(questionnaire_id);
CREATE INDEX idx_responses_questionnaire ON responses(questionnaire_id);
CREATE INDEX idx_responses_question ON responses(question_id);
CREATE INDEX idx_options_question ON question_options(question_id);
CREATE INDEX idx_mappings_question ON clinical_concept_mappings(question_id);
CREATE INDEX idx_mappings_response ON clinical_concept_mappings(response_id); 