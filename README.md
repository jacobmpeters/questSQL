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