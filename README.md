# QuestSQL

A SQL-first questionnaire development and administration system that unifies questionnaire design, data collection, and analysis through a single, well-structured data model.

## Vision

QuestSQL aims to revolutionize how health questionnaires are developed, administered, and analyzed by making SQL the foundation of everything. This approach provides several key benefits:

### SQL-First Design
- All questionnaire logic and relationships are encoded directly in SQL
- Questionnaire development happens through SQL DDL statements
- Enables multiple layers of abstraction:
  - REST APIs for DDL operations
  - SDKs for simplified interaction
  - Human-readable markdown language for questionnaire authoring

### Unified Data Model
- Single source of truth for questionnaire structure and data
- Eliminates the need for separate data dictionaries
- Enforces data quality and consistency through database constraints
- Supports both questionnaire development and data collection

### Client-Side Administration
- Lightweight SQLite-based UI for survey administration
- Direct interaction with the data model
- Real-time response collection and storage
- No complex middleware required

### Analytics Toolkit
- DuckDB-powered analysis capabilities
- Support for arbitrary questionnaire analysis
- Extensible API for community contributions
- SDKs for R, Python, and other languages

## Core Principles

1. **Simplicity First**
   - Minimal dependencies
   - Clear, straightforward data model
   - Easy to understand and extend

2. **Quality by Design**
   - Built-in constraints for data quality
   - Enforced best practices
   - Standardized questionnaire structure

3. **Extensibility**
   - Flexible enough for various study needs
   - Community-driven development
   - Multiple abstraction layers

4. **Integration**
   - Unified development and administration
   - Seamless analysis capabilities
   - No separate documentation needed

## Data Model

The schema is designed to support all aspects of questionnaire lifecycle:

```mermaid
erDiagram
    questionnaires {
        int questionnaire_id PK
        string title
        string description
        string version
        datetime created_at
        datetime updated_at
    }
    concepts {
        int concept_id PK
        string code UK
        string name
        string description
        string concept_type
        datetime created_at
    }
    questions {
        int question_id PK
        int questionnaire_id FK
        int concept_id FK
        string question_text
        string question_type
        boolean is_required
        int display_order
        int parent_question_id FK
        int loop_question_id FK
        int loop_position
        datetime created_at
    }
    question_options {
        int option_id PK
        int question_id FK
        string option_text
        string option_value
        int display_order
        datetime created_at
    }
    grid_columns {
        int column_id PK
        int question_id FK
        string column_text
        string column_value
        int display_order
        datetime created_at
    }
    skip_logic {
        int skip_logic_id PK
        int question_id FK
        int target_question_id FK
        string condition_type
        string condition_value
        datetime created_at
    }
    responses {
        int response_id PK
        int questionnaire_id FK
        int question_id FK
        string response_value
        int loop_instance
        datetime created_at
    }

    questionnaires ||--o{ questions : "questionnaire_id"
    concepts ||--o{ questions : "concept_id"
    questions ||--o{ questions : "parent_question_id"
    questions ||--o{ questions : "loop_question_id"
    questions ||--o{ question_options : "question_id"
    questions ||--o{ grid_columns : "question_id"
    questions ||--o{ skip_logic : "question_id"
    questions ||--o{ skip_logic : "target_question_id"
    questions ||--o{ responses : "question_id"
    questionnaires ||--o{ responses : "questionnaire_id"
```

## Question Types and Implementation

QuestSQL supports a wide range of question types through its flexible data model. Here's how each type is implemented:

### 1. True/False Questions
Simple yes/no questions that require a boolean response.

```sql
-- Create a true/false question
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    is_required,
    display_order
) VALUES (
    1,
    'Have you experienced any chest pain in the last 24 hours?',
    'true_false',
    true,
    1
);
```

### 2. Multiple Choice Questions
Single-selection questions with predefined options.

```sql
-- Create a multiple choice question
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    is_required,
    display_order
) VALUES (
    1,
    'What is your current pain level?',
    'multiple_choice',
    true,
    2
);

-- Add options for the multiple choice question
INSERT INTO question_options (
    question_id,
    option_text,
    option_value,
    display_order
) VALUES 
    (2, 'No pain', '0', 1),
    (2, 'Mild pain', '1', 2),
    (2, 'Moderate pain', '2', 3),
    (2, 'Severe pain', '3', 4);
```

### 3. Select-All-That-Apply
Multiple selection questions where respondents can choose multiple options.

```sql
-- Create a select-all-that-apply question
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    is_required,
    display_order
) VALUES (
    1,
    'Which symptoms have you experienced? (Select all that apply)',
    'select_all',
    false,
    3
);

-- Add options for the select-all question
INSERT INTO question_options (
    question_id,
    option_text,
    option_value,
    display_order
) VALUES 
    (3, 'Headache', 'headache', 1),
    (3, 'Nausea', 'nausea', 2),
    (3, 'Fatigue', 'fatigue', 3),
    (3, 'Dizziness', 'dizziness', 4);
```

### 4. Grid Questions
Matrix-style questions with rows and columns.

```sql
-- Create a grid question
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    is_required,
    display_order
) VALUES (
    1,
    'Rate your symptoms on a scale of 1-5',
    'grid',
    true,
    4
);

-- Add grid columns (rating scale)
INSERT INTO grid_columns (
    question_id,
    column_text,
    column_value,
    display_order
) VALUES 
    (4, '1', '1', 1),
    (4, '2', '2', 2),
    (4, '3', '3', 3),
    (4, '4', '4', 4),
    (4, '5', '5', 5);

-- Add grid rows (symptoms)
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    is_required,
    display_order,
    parent_question_id
) VALUES 
    (1, 'Pain', 'grid_row', true, 1, 4),
    (1, 'Fatigue', 'grid_row', true, 2, 4),
    (1, 'Sleep quality', 'grid_row', true, 3, 4);
```

### 5. Loop Questions
Repeating sections of questions.

```sql
-- Create a loop question (parent)
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    is_required,
    display_order
) VALUES (
    1,
    'List your medications',
    'loop',
    false,
    5
);

-- Add looped questions
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    is_required,
    display_order,
    loop_question_id,
    loop_position
) VALUES 
    (1, 'Medication name', 'text', true, 1, 5, 1),
    (1, 'Dosage', 'text', true, 2, 5, 2),
    (1, 'Frequency', 'text', true, 3, 5, 3);
```

### 6. Skip Logic
Conditional question display based on previous answers.

```sql
-- Add skip logic
INSERT INTO skip_logic (
    question_id,
    target_question_id,
    condition_type,
    condition_value
) VALUES (
    2,  -- Source question (pain level)
    4,  -- Target question (grid question)
    'equals',
    '3'  -- Skip to grid if pain is severe
);
```

### Response Storage
All responses are stored in a unified format in the `responses` table:

```sql
-- Example responses
INSERT INTO responses (
    questionnaire_id,
    question_id,
    response_value,
    loop_instance
) VALUES 
    (1, 1, 'true', NULL),                    -- True/False response
    (1, 2, '2', NULL),                       -- Multiple choice response
    (1, 3, 'headache,nausea', NULL),         -- Select-all response (comma-separated)
    (1, 4, '3', NULL),                       -- Grid response
    (1, 5, '1', NULL),                       -- Loop question response
    (1, 6, 'Aspirin', 1),                    -- First loop instance
    (1, 7, '100mg', 1),
    (1, 8, 'Twice daily', 1),
    (1, 6, 'Ibuprofen', 2),                  -- Second loop instance
    (1, 7, '200mg', 2),
    (1, 8, 'Three times daily', 2);
```

## Features

- **Questionnaire Development**
  - SQL-based questionnaire definition
  - Support for all common question types
  - Skip logic and conditional questions
  - Loop questions for repeating sections
  - Grid questions
  - Standardized concept mapping

- **Survey Administration**
  - SQLite-based client UI
  - Real-time response collection
  - Offline capability
  - Data validation

- **Analysis**
  - DuckDB-powered analytics
  - Support for arbitrary questionnaires
  - Extensible analysis toolkit
  - Multiple language SDKs

## Getting Started

[Coming soon]

## Contributing

[Coming soon]

## License

[Coming soon] 