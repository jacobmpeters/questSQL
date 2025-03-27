-- Advanced Question Types Schema
-- This schema adds support for complex question types like grid questions

-- Grid questions
CREATE TABLE grid_questions (
    grid_id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER REFERENCES questions(question_id),
    grid_type TEXT NOT NULL CHECK (
        grid_type IN ('single_select', 'multi_select', 'numeric')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE grid_columns (
    column_id INTEGER PRIMARY KEY AUTOINCREMENT,
    grid_id INTEGER REFERENCES grid_questions(grid_id),
    column_text TEXT NOT NULL,
    column_value TEXT NOT NULL,
    concept_id INTEGER NOT NULL,
    vocabulary_id TEXT NOT NULL,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE grid_rows (
    row_id INTEGER PRIMARY KEY AUTOINCREMENT,
    grid_id INTEGER REFERENCES grid_questions(grid_id),
    row_text TEXT NOT NULL,
    row_value TEXT NOT NULL,
    concept_id INTEGER NOT NULL,
    vocabulary_id TEXT NOT NULL,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE grid_responses (
    response_id INTEGER PRIMARY KEY AUTOINCREMENT,
    grid_id INTEGER REFERENCES grid_questions(grid_id),
    column_id INTEGER REFERENCES grid_columns(column_id),
    row_id INTEGER REFERENCES grid_rows(row_id),
    response_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_grid_questions_question ON grid_questions(question_id);
CREATE INDEX idx_grid_columns_grid ON grid_columns(grid_id);
CREATE INDEX idx_grid_rows_grid ON grid_rows(grid_id);
CREATE INDEX idx_grid_responses_grid ON grid_responses(grid_id);
CREATE INDEX idx_grid_responses_column ON grid_responses(column_id);
CREATE INDEX idx_grid_responses_row ON grid_responses(row_id);

-- Update question types
ALTER TABLE questions
    ADD CONSTRAINT valid_question_type CHECK (
        question_type IN (
            'true_false', 'multiple_choice', 'text',
            'grid_single', 'grid_multi', 'grid_numeric'
        )
    ); 