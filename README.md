# Questionnaire Database Schema

This is a response-centric relational data model for health questionnaire data that supports various question types, skip logic, and loop questions.

## Entity Relationship Diagram

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

## Schema Description

The schema consists of the following tables:

1. `questionnaires`: Stores metadata about questionnaires
   - Primary key: `questionnaire_id`
   - Contains title, description, version, and timestamps

2. `concepts`: Stores standardized medical concepts
   - Primary key: `concept_id`
   - Contains code (unique), name, description, and type
   - Used for standardized terminology mapping

3. `questions`: Core table for all question types
   - Primary key: `question_id`
   - Supports various question types (true/false, multiple choice, grid, etc.)
   - Handles nested questions and loop questions
   - Links to questionnaires and concepts

4. `question_options`: Options for multiple choice and select-all questions
   - Primary key: `option_id`
   - Contains option text, value, and display order
   - Links to parent question

5. `grid_columns`: Columns for grid questions
   - Primary key: `column_id`
   - Contains column text, value, and display order
   - Links to parent question

6. `skip_logic`: Conditional question display logic
   - Primary key: `skip_logic_id`
   - Defines conditions and target questions
   - Links source and target questions

7. `responses`: Stores all user responses
   - Primary key: `response_id`
   - Links to both questionnaire and specific question
   - Supports loop questions through `loop_instance`

## Features

- Supports all common question types:
  - True/false
  - Multiple choice
  - Select-all-that-apply
  - Grid questions
  - Free text
  - Loop questions
- Skip logic for conditional question display
- Standardized concept mapping
- Nested questions
- Loop questions for repeating sections
- Timestamps for tracking creation/updates 