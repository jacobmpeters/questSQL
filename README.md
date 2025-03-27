# QuestSQL

A SQL-first questionnaire development and administration system that unifies questionnaire design, data collection, and analysis through a single, well-structured data model. Built with OMOP CDM compatibility in mind, it enables seamless integration with clinical data systems.

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Data Model](#core-data-model)
4. [Clinical Concept Mapping](#clinical-concept-mapping)
5. [Progressive Implementation](#progressive-implementation)
6. [OMOP Integration](#omop-integration)
7. [Examples](#examples)
8. [Validation and Constraints](#validation-and-constraints)
9. [Analytics and Export](#analytics-and-export)

## Overview

QuestSQL provides a unified approach to health questionnaire development and administration:

- **SQL-First Design**: All questionnaire logic encoded directly in SQL
- **Concept Mapping**: Enforced mapping to clinical concepts during questionnaire development
- **OMOP Compatible**: Direct mapping to clinical concepts and vocabularies
- **Self-Documenting**: Schema serves as the data dictionary
- **Analytics Ready**: Built-in support for clinical data analysis

### Key Principles

1. **Development-Time Mapping**
   - Questions must map to standard clinical concepts during creation
   - Response options must map to standard clinical values
   - Question-response pairs must form valid clinical observations
   - All mappings are enforced through database constraints

2. **Vocabulary Standardization**
   - Uses standard clinical vocabularies (SNOMED, LOINC, RxNorm)
   - Maintains explicit vocabulary source tracking
   - Enables cross-vocabulary mapping
   - Supports OMOP CDM compatibility

3. **Data Quality**
   - Enforces standard concept usage
   - Validates against clinical vocabularies
   - Maintains data consistency
   - Supports quality checks

## Architecture

The system is built around three core components:

```mermaid
graph LR
    subgraph Development
        DDL[SQL DDL Library]
        API[REST API Layer]
        SDK[Language SDKs]
    end

    subgraph SQL Backend
        SQLite[(SQLite Database)]
    end

    subgraph Analytics
        DuckDB[(DuckDB Analytics)]
        R[R Interface]
        Python[Python Interface]
    end

    DDL <--> SQLite
    API --> DDL
    SDK --> API

    SQLite <--> DuckDB
    DuckDB <--> R
    DuckDB <--> Python

    style DDL fill:#f9f,stroke:#333,stroke-width:2px
    style SQLite fill:#bbf,stroke:#333,stroke-width:2px
    style DuckDB fill:#bfb,stroke:#333,stroke-width:2px
```

### Key Components
1. **Development Layer**
   - SQL DDL Library for schema management
   - REST API for remote operations
   - SDKs for language-specific integration

2. **SQL Backend**
   - SQLite for local data storage
   - Direct DDL interaction
   - Real-time data collection

3. **Analytics Layer**
   - DuckDB for high-performance analysis
   - R and Python interfaces
   - Extensible analytics toolkit

## Core Data Model

The foundation of QuestSQL is its concept-mapped data model, with question-response pairs as the fundamental mappable unit:

```mermaid
erDiagram
    questionnaires ||--o{ questions : contains
    questions ||--o{ responses : receives
    questions ||--o{ question_options : has
    questions ||--o{ clinical_concept_mappings : "maps to"
    responses ||--o{ clinical_concept_mappings : "maps to"
    clinical_concept_mappings ||--o{ concepts : "references"
    questions ||--o{ question_response_concept_mappings : "forms"
    responses ||--o{ question_response_concept_mappings : "forms"
    question_response_concept_mappings ||--o{ concepts : "maps to"

    questionnaires {
        integer questionnaire_id PK
        text title
        text description
        timestamp created_at
    }

    questions {
        integer question_id PK
        integer questionnaire_id FK
        text question_text
        text question_type
        boolean is_required
        integer display_order
        timestamp created_at
    }

    responses {
        integer response_id PK
        integer questionnaire_id FK
        integer question_id FK
        text response_value
        timestamp created_at
    }

    question_options {
        integer option_id PK
        integer question_id FK
        text option_text
        text option_value
        integer display_order
    }

    clinical_concept_mappings {
        integer mapping_id PK
        text mapped_type
        integer question_id FK
        integer response_id FK
        integer concept_id FK
        text vocabulary_id
        timestamp created_at
        timestamp updated_at
    }

    question_response_concept_mappings {
        integer mapping_id PK
        integer question_id FK
        integer response_id FK
        integer concept_id FK
        text vocabulary_id
        text domain_id
        timestamp created_at
        timestamp updated_at
    }

    concepts {
        integer concept_id PK
        text code
        text name
        text description
        text concept_type
        timestamp created_at
    }
```

### Key Features
- Question-response pairs are the fundamental mappable unit
- Each pair maps to a complete clinical observation
- Questions map to standard clinical concepts (e.g., "Blood Pressure" maps to concept_id 3004249)
- Responses map to standard clinical values (e.g., "High" maps to concept_id 4171373)
- Question-response pairs map to complete clinical observations (e.g., "High Blood Pressure" maps to concept_id 4171373)
- Question options map to standard values (e.g., "Yes" maps to concept_id 4188539)
- Built-in support for multiple question types
- Standardized value sets through concept mapping
- Temporal data tracking
- Explicit vocabulary tracking (SNOMED, RxNorm, etc.)

## Clinical Concept Mapping

The `clinical_concept_mappings` table provides explicit mapping between questionnaire elements and clinical concepts:

```sql
CREATE TABLE clinical_concept_mappings (
    mapping_id INTEGER PRIMARY KEY AUTOINCREMENT,
    -- What is being mapped (question, response, or question-response pair)
    mapped_type TEXT NOT NULL CHECK (mapped_type IN ('question', 'response', 'pair')),
    -- References to the mapped elements
    question_id INTEGER,
    response_id INTEGER,
    -- The clinical concept this maps to
    concept_id INTEGER NOT NULL,
    -- The vocabulary this concept comes from (e.g., 'SNOMED', 'RxNorm')
    vocabulary_id TEXT NOT NULL,
    -- When this mapping was created/updated
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Ensure we have the right combination of IDs based on mapped_type
    CONSTRAINT valid_mapping CHECK (
        (mapped_type = 'question' AND question_id IS NOT NULL AND response_id IS NULL) OR
        (mapped_type = 'response' AND response_id IS NOT NULL AND question_id IS NULL) OR
        (mapped_type = 'pair' AND question_id IS NOT NULL AND response_id IS NOT NULL)
    ),
    -- Foreign key constraints
    FOREIGN KEY (question_id) REFERENCES questions(question_id),
    FOREIGN KEY (response_id) REFERENCES responses(response_id),
    FOREIGN KEY (concept_id) REFERENCES concepts(concept_id)
);

-- Example mappings
INSERT INTO clinical_concept_mappings (
    mapped_type,
    question_id,
    concept_id,
    vocabulary_id
) VALUES 
    ('question', 1, 3004249, 'SNOMED'),  -- Blood pressure question
    ('question', 2, 3012888, 'SNOMED');  -- Heart rate question

INSERT INTO clinical_concept_mappings (
    mapped_type,
    response_id,
    concept_id,
    vocabulary_id
) VALUES 
    ('response', 1, 4171373, 'SNOMED'),  -- High blood pressure response
    ('response', 2, 4171374, 'SNOMED');  -- Normal blood pressure response

-- Map a specific question-response pair
INSERT INTO clinical_concept_mappings (
    mapped_type,
    question_id,
    response_id,
    concept_id,
    vocabulary_id
) VALUES 
    ('pair', 1, 1, 4171373, 'SNOMED');  -- High blood pressure observation
```

## Progressive Implementation

QuestSQL is built incrementally, with each level adding new capabilities:

### 1. Basic Model
The foundation supports core question types and basic concept mapping:

```sql
-- Basic question types
CREATE TABLE questions (
    question_id INTEGER PRIMARY KEY,
    questionnaire_id INTEGER REFERENCES questionnaires(questionnaire_id),
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (
        question_type IN ('true_false', 'multiple_choice', 'text')
    ),
    is_required BOOLEAN DEFAULT false,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Basic concept mapping
CREATE TABLE clinical_concept_mappings (
    mapping_id INTEGER PRIMARY KEY,
    mapped_type TEXT NOT NULL CHECK (mapped_type IN ('question', 'response')),
    question_id INTEGER REFERENCES questions(question_id),
    response_id INTEGER REFERENCES responses(response_id),
    concept_id INTEGER NOT NULL,
    vocabulary_id TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Question-Response Pair Mapping
Adds support for mapping complete clinical observations:

```sql
-- Question-response pair mapping
CREATE TABLE question_response_concept_mappings (
    mapping_id INTEGER PRIMARY KEY,
    question_id INTEGER REFERENCES questions(question_id),
    response_id INTEGER REFERENCES responses(response_id),
    concept_id INTEGER NOT NULL,
    vocabulary_id TEXT NOT NULL,
    domain_id TEXT NOT NULL CHECK (
        domain_id IN ('Condition', 'Measurement', 'Drug', 'Observation')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Ensure we have both question and response
    CONSTRAINT valid_pair CHECK (
        question_id IS NOT NULL AND response_id IS NOT NULL
    )
);

-- Example: Blood pressure observation
INSERT INTO question_response_concept_mappings (
    question_id,
    response_id,
    concept_id,
    vocabulary_id,
    domain_id
) VALUES (
    1,  -- Blood pressure question
    1,  -- High blood pressure response
    4171373,  -- High blood pressure concept
    'SNOMED',
    'Measurement'
);
```

### 3. Advanced Question Types
Adds support for complex question types with pair mapping:

```sql
-- Grid questions with pair mapping
CREATE TABLE grid_columns (
    column_id INTEGER PRIMARY KEY,
    question_id INTEGER REFERENCES questions(question_id),
    column_text TEXT NOT NULL,
    column_value TEXT NOT NULL,
    concept_id INTEGER NOT NULL,
    vocabulary_id TEXT NOT NULL,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Example: Blood pressure grid
INSERT INTO grid_columns (
    question_id,
    column_text,
    column_value,
    concept_id,
    vocabulary_id
) VALUES 
(1, 'Systolic', 'systolic', 3004249, 'SNOMED'),
(1, 'Diastolic', 'diastolic', 3004249, 'SNOMED');

-- Map grid responses to observations
INSERT INTO question_response_concept_mappings (
    question_id,
    response_id,
    concept_id,
    vocabulary_id,
    domain_id
) VALUES 
(1, 1, 4171373, 'SNOMED', 'Measurement'),  -- High systolic
(1, 2, 4171374, 'SNOMED', 'Measurement');  -- Normal diastolic
```

### 4. OMOP Integration
Adds comprehensive OMOP CDM mapping support:

```sql
-- OMOP observation mapping
CREATE VIEW omop_observations AS
SELECT 
    p.person_id,
    m.concept_id as observation_concept_id,
    r.created_at as observation_date,
    r.response_value as value_as_string,
    m2.concept_id as value_as_concept_id,
    m.domain_id,
    m.vocabulary_id
FROM question_response_concept_mappings m
JOIN responses r ON m.response_id = r.response_id
JOIN questions q ON m.question_id = q.question_id
JOIN persons p ON r.person_id = p.person_id
LEFT JOIN clinical_concept_mappings m2 ON r.response_id = m2.response_id
WHERE m2.mapped_type = 'response';
```

## OMOP Integration

QuestSQL directly maps to OMOP CDM through concept relationships:

### Domain Mapping
```sql
-- Example: Blood pressure measurement
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    concept_id,
    domain_id
) VALUES (
    1,
    'What is your blood pressure?',
    'numeric',
    3004249,  -- Blood pressure concept
    'Measurement'
);

-- Example: Medication adherence
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    concept_id,
    domain_id
) VALUES (
    1,
    'Are you taking your prescribed medications?',
    'multiple_choice',
    4023213,  -- Medication adherence concept
    'Drug'
);
```

### Vocabulary Support
```sql
-- Example: LOINC-based lab question
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    concept_id,
    vocabulary_id
) VALUES (
    1,
    'What was your last HbA1c result?',
    'numeric',
    3004410,  -- HbA1c concept
    'LOINC'
);

-- Example: SNOMED-based condition question
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    concept_id,
    vocabulary_id
) VALUES (
    1,
    'Have you been diagnosed with diabetes?',
    'true_false',
    201820,  -- Diabetes concept
    'SNOMED'
);
```

## Examples

### Health Assessment Questionnaire
```sql
-- Create questionnaire
INSERT INTO questionnaires (title, description) VALUES (
    'Health Assessment',
    'Basic health status assessment'
);

-- Add blood pressure question
INSERT INTO questions (
    questionnaire_id,
    question_text,
    question_type,
    concept_id
) VALUES (
    1,
    'What is your blood pressure?',
    'numeric',
    3004249  -- Blood pressure concept
);

-- Add response options
INSERT INTO question_options (
    question_id,
    option_text,
    option_value,
    concept_id
) VALUES 
(1, 'Normal', 'normal', 4171374),
(1, 'High', 'high', 4171373),
(1, 'Low', 'low', 4171375);
```

### Query Examples
```sql
-- Get all questions with their concepts
SELECT 
    q.question_text,
    c.name as concept_name,
    c.code as concept_code
FROM questions q
JOIN concepts c ON q.concept_id = c.concept_id;

-- Get responses with standardized values
SELECT 
    r.response_value,
    c.name as standardized_value
FROM responses r
JOIN concepts c ON r.concept_id = c.concept_id;
```

## Validation and Constraints

QuestSQL uses SQL constraints and assertions to ensure data integrity and validity:

### 1. Question Type Validation
```sql
-- Enforce valid question types
CREATE TABLE questions (
    -- ... other columns ...
    question_type TEXT NOT NULL CHECK (
        question_type IN (
            'true_false',
            'multiple_choice',
            'select_all',
            'grid',
            'grid_row',
            'loop',
            'text',
            'numeric',
            'datetime'
        )
    )
);

-- Ensure grid questions have columns
CREATE TRIGGER validate_grid_question
AFTER INSERT ON questions
BEGIN
    SELECT CASE
        WHEN NEW.question_type = 'grid' AND NOT EXISTS (
            SELECT 1 FROM grid_columns 
            WHERE question_id = NEW.question_id
        )
        THEN RAISE(ABORT, 'Grid questions must have at least one column')
    END;
END;
```

### 2. Response Validation
```sql
-- Validate numeric responses
CREATE TRIGGER validate_numeric_response
BEFORE INSERT ON responses
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM questions q
            WHERE q.question_id = NEW.question_id
            AND q.question_type = 'numeric'
        )
        AND CAST(NEW.response_value AS DECIMAL) IS NULL
        THEN RAISE(ABORT, 'Invalid numeric response')
    END;
END;

-- Validate datetime responses
CREATE TRIGGER validate_datetime_response
BEFORE INSERT ON responses
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM questions q
            WHERE q.question_id = NEW.question_id
            AND q.question_type = 'datetime'
        )
        AND datetime(NEW.response_value) IS NULL
        THEN RAISE(ABORT, 'Invalid datetime response')
    END;
END;
```

### 3. Required Field Validation
```sql
-- Ensure required questions are answered
CREATE TRIGGER validate_required_questions
AFTER INSERT ON questionnaires
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM questions q
            WHERE q.questionnaire_id = NEW.questionnaire_id
            AND q.is_required = true
            AND NOT EXISTS (
                SELECT 1 FROM responses r
                WHERE r.question_id = q.question_id
            )
        )
        THEN RAISE(ABORT, 'Required questions must be answered')
    END;
END;
```

### 4. Concept Mapping Validation
```sql
-- Ensure questions have valid concept mappings
CREATE TRIGGER validate_concept_mapping
BEFORE INSERT ON questions
BEGIN
    SELECT CASE
        WHEN NEW.concept_id IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM concepts c
            WHERE c.concept_id = NEW.concept_id
        )
        THEN RAISE(ABORT, 'Invalid concept mapping')
    END;
END;

-- Validate response concept mappings
CREATE TRIGGER validate_response_concept
BEFORE INSERT ON responses
BEGIN
    SELECT CASE
        WHEN NEW.concept_id IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM concepts c
            WHERE c.concept_id = NEW.concept_id
        )
        THEN RAISE(ABORT, 'Invalid response concept mapping')
    END;
END;
```

### 5. Grid Question Validation
```sql
-- Ensure grid questions have valid structure
CREATE TRIGGER validate_grid_structure
AFTER INSERT ON grid_columns
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM questions q
            WHERE q.question_id = NEW.question_id
            AND q.question_type != 'grid'
        )
        THEN RAISE(ABORT, 'Grid columns only allowed for grid questions')
    END;
END;

-- Validate grid responses
CREATE TRIGGER validate_grid_response
BEFORE INSERT ON responses
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM questions q
            WHERE q.question_id = NEW.question_id
            AND q.question_type = 'grid'
        )
        AND NOT EXISTS (
            SELECT 1 FROM grid_columns gc
            WHERE gc.question_id = NEW.question_id
            AND gc.column_value = NEW.response_value
        )
        THEN RAISE(ABORT, 'Invalid grid response value')
    END;
END;
```

### 6. Loop Question Validation
```sql
-- Validate loop question structure
CREATE TRIGGER validate_loop_structure
BEFORE INSERT ON questions
BEGIN
    SELECT CASE
        WHEN NEW.question_type = 'loop'
        AND NEW.loop_question_id IS NULL
        THEN RAISE(ABORT, 'Loop questions must reference a parent question')
    END;
END;

-- Ensure loop responses have valid instances
CREATE TRIGGER validate_loop_response
BEFORE INSERT ON responses
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM questions q
            WHERE q.question_id = NEW.question_id
            AND q.question_type = 'loop'
        )
        AND NEW.loop_instance IS NULL
        THEN RAISE(ABORT, 'Loop responses must specify an instance')
    END;
END;
```

### 7. Temporal Validation
```sql
-- Ensure response timestamps are valid
CREATE TRIGGER validate_response_timestamp
BEFORE INSERT ON responses
BEGIN
    SELECT CASE
        WHEN NEW.created_at > CURRENT_TIMESTAMP
        THEN RAISE(ABORT, 'Response timestamp cannot be in the future')
    END;
END;

-- Validate questionnaire completion order
CREATE TRIGGER validate_questionnaire_order
BEFORE INSERT ON responses
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM responses r
            WHERE r.questionnaire_id = NEW.questionnaire_id
            AND r.created_at > NEW.created_at
        )
        THEN RAISE(ABORT, 'Responses must be inserted in chronological order')
    END;
END;
```

These validations ensure:
- Data type consistency
- Required field completion
- Valid concept mappings
- Proper question structure
- Temporal integrity
- Response validity

## ID Management and Uniqueness

QuestSQL enforces data quality through various constraints and validation rules:

### 1. Questionnaire-Level Constraints
```sql
-- Ensure questionnaire titles are unique
CREATE UNIQUE INDEX idx_questionnaire_title ON questionnaires(title);

-- Prevent duplicate questions within a questionnaire
CREATE UNIQUE INDEX idx_question_order ON questions(questionnaire_id, display_order);

-- Ensure response options are unique within a question
CREATE UNIQUE INDEX idx_option_order ON question_options(question_id, display_order);
```

### 2. Response Validation
```sql
-- Ensure required questions are answered
CREATE TRIGGER validate_required_questions
AFTER INSERT ON responses
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM questions q
            WHERE q.questionnaire_id = NEW.questionnaire_id
            AND q.is_required = 1
            AND NOT EXISTS (
                SELECT 1 FROM responses r
                WHERE r.question_id = q.question_id
                AND r.questionnaire_id = NEW.questionnaire_id
            )
        )
        THEN RAISE(ABORT, 'Required questions must be answered')
    END;
END;

-- Validate numeric responses
CREATE TRIGGER validate_numeric_responses
AFTER INSERT ON responses
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM questions q
            WHERE q.question_id = NEW.question_id
            AND q.question_type = 'numeric'
            AND CAST(NEW.response_value AS DECIMAL) IS NULL
        )
        THEN RAISE(ABORT, 'Invalid numeric response')
    END;
END;
```

### 3. Concept Mapping Validation
```sql
-- Ensure questions map to valid concepts
CREATE TRIGGER validate_question_concepts
AFTER INSERT ON clinical_concept_mappings
BEGIN
    SELECT CASE
        WHEN NEW.mapped_type = 'question'
        AND NOT EXISTS (
            SELECT 1 FROM concepts c
            WHERE c.concept_id = NEW.concept_id
            AND c.concept_type IN ('Measurement', 'Observation')
        )
        THEN RAISE(ABORT, 'Invalid question concept mapping')
    END;
END;

-- Validate response concept mappings
CREATE TRIGGER validate_response_concepts
AFTER INSERT ON clinical_concept_mappings
BEGIN
    SELECT CASE
        WHEN NEW.mapped_type = 'response'
        AND NOT EXISTS (
            SELECT 1 FROM concepts c
            WHERE c.concept_id = NEW.concept_id
            AND c.concept_type IN ('Value', 'Answer')
        )
        THEN RAISE(ABORT, 'Invalid response concept mapping')
    END;
END;
```

### 4. Temporal Constraints
```sql
-- Ensure response timestamps are valid
CREATE TRIGGER validate_response_timestamps
AFTER INSERT ON responses
BEGIN
    SELECT CASE
        WHEN NEW.created_at > CURRENT_TIMESTAMP
        THEN RAISE(ABORT, 'Response timestamp cannot be in the future')
    END;
END;

-- Track concept mapping updates
CREATE TRIGGER track_concept_mapping_updates
AFTER UPDATE ON clinical_concept_mappings
BEGIN
    UPDATE clinical_concept_mappings
    SET updated_at = CURRENT_TIMESTAMP
    WHERE mapping_id = NEW.mapping_id;
END;
```

### 5. Data Integrity Checks
```sql
-- Verify questionnaire completeness
CREATE VIEW questionnaire_completeness AS
SELECT 
    q.questionnaire_id,
    q.title,
    COUNT(DISTINCT q.question_id) as total_questions,
    COUNT(DISTINCT r.response_id) as answered_questions,
    CASE 
        WHEN COUNT(DISTINCT q.question_id) = COUNT(DISTINCT r.response_id)
        THEN 1 ELSE 0 
    END as is_complete
FROM questionnaires q
LEFT JOIN questions qs ON q.questionnaire_id = qs.questionnaire_id
LEFT JOIN responses r ON qs.question_id = r.question_id
GROUP BY q.questionnaire_id, q.title;

-- Check concept mapping coverage
CREATE VIEW concept_mapping_coverage AS
SELECT 
    q.questionnaire_id,
    q.title,
    COUNT(DISTINCT q.question_id) as total_questions,
    COUNT(DISTINCT m.mapping_id) as mapped_questions,
    CASE 
        WHEN COUNT(DISTINCT q.question_id) = COUNT(DISTINCT m.mapping_id)
        THEN 1 ELSE 0 
    END as is_fully_mapped
FROM questionnaires q
LEFT JOIN questions qs ON q.questionnaire_id = qs.questionnaire_id
LEFT JOIN clinical_concept_mappings m ON qs.question_id = m.question_id
GROUP BY q.questionnaire_id, q.title;
```

## Analytics and Export

QuestSQL provides built-in analytics capabilities and export options:

### 1. Response Analysis
```sql
-- Basic response statistics
SELECT 
    q.question_text,
    COUNT(r.response_id) as response_count,
    AVG(CAST(r.response_value AS DECIMAL)) as avg_value
FROM questions q
LEFT JOIN responses r ON q.question_id = r.question_id
GROUP BY q.question_id, q.question_text;

-- Response distribution
SELECT 
    r.response_value,
    COUNT(*) as count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage
FROM responses r
WHERE r.question_id = 1
GROUP BY r.response_value;
```

### 2. Concept-Based Analysis
```sql
-- Analyze responses by clinical concept
SELECT 
    c.name as concept_name,
    COUNT(*) as response_count,
    AVG(CAST(r.response_value AS DECIMAL)) as avg_value
FROM responses r
JOIN clinical_concept_mappings m ON r.response_id = m.response_id
JOIN concepts c ON m.concept_id = c.concept_id
GROUP BY c.concept_id, c.name;

-- Track concept mapping coverage
SELECT 
    q.questionnaire_id,
    COUNT(DISTINCT q.question_id) as total_questions,
    COUNT(DISTINCT m.mapping_id) as mapped_questions,
    COUNT(DISTINCT m.mapping_id) * 100.0 / COUNT(DISTINCT q.question_id) as mapping_coverage
FROM questions q
LEFT JOIN clinical_concept_mappings m ON q.question_id = m.question_id
GROUP BY q.questionnaire_id;
```

### 3. Temporal Analysis
```sql
-- Response trends over time
SELECT 
    DATE(r.created_at) as response_date,
    COUNT(*) as response_count,
    AVG(CAST(r.response_value AS DECIMAL)) as avg_value
FROM responses r
WHERE r.question_id = 1
GROUP BY DATE(r.created_at)
ORDER BY response_date;

-- Completion time analysis
SELECT 
    q.questionnaire_id,
    MIN(r.created_at) as first_response,
    MAX(r.created_at) as last_response,
    JULIANDAY(MAX(r.created_at)) - JULIANDAY(MIN(r.created_at)) as completion_days
FROM responses r
JOIN questions q ON r.question_id = q.question_id
GROUP BY q.questionnaire_id;
```

### 4. Export Options
```sql
-- Export to CSV format
.mode csv
.output responses.csv
SELECT 
    q.question_text,
    r.response_value,
    r.created_at,
    c.name as concept_name
FROM responses r
JOIN questions q ON r.question_id = q.question_id
LEFT JOIN clinical_concept_mappings m ON r.response_id = m.response_id
LEFT JOIN concepts c ON m.concept_id = c.concept_id;
.output stdout

-- Export to JSON format
.mode json
.output responses.json
SELECT 
    q.question_text,
    r.response_value,
    r.created_at,
    c.name as concept_name
FROM responses r
JOIN questions q ON r.question_id = q.question_id
LEFT JOIN clinical_concept_mappings m ON r.response_id = m.response_id
LEFT JOIN concepts c ON m.concept_id = c.concept_id;
.output stdout
```

### 5. Quality Metrics
```sql
-- Response completeness
SELECT 
    q.questionnaire_id,
    COUNT(DISTINCT q.question_id) as total_questions,
    COUNT(DISTINCT r.response_id) as answered_questions,
    COUNT(DISTINCT r.response_id) * 100.0 / COUNT(DISTINCT q.question_id) as completion_rate
FROM questions q
LEFT JOIN responses r ON q.question_id = r.question_id
GROUP BY q.questionnaire_id;

-- Concept mapping quality
SELECT 
    m.vocabulary_id,
    COUNT(*) as mapping_count,
    COUNT(DISTINCT m.concept_id) as unique_concepts,
    COUNT(DISTINCT m.question_id) as mapped_questions
FROM clinical_concept_mappings m
GROUP BY m.vocabulary_id;
```

These analytics capabilities enable:
- Response pattern analysis
- Clinical concept tracking
- Temporal trend analysis
- Data quality monitoring
- Flexible data export

## Getting Started

[Coming soon]

## Contributing

[Coming soon]

## License

[Coming soon]

## Concept Mapping

The model uses concept mapping similar to OMOP CDM:

1. **Question Concepts**
   - Each question can map to a standard clinical concept
   - Example: A question about "Blood Pressure" maps to concept_id 3004249
   - This enables standardized question interpretation

2. **Response Concepts**
   - Each response can map to a standard clinical value
   - Example: A response of "High" to a blood pressure question maps to concept_id 4171373
   - This enables standardized response interpretation

3. **Option Concepts**
   - Multiple choice options can map to standard values
   - Example: "Yes" maps to concept_id 4188539
   - This ensures consistent value representation

4. **Grid Concepts**
   - Grid rows and columns can map to standard concepts
   - Example: A row for "Systolic" maps to concept_id 3004249
   - This enables structured data collection

### OMOP CDM Compatibility

QuestSQL's concept mapping aligns directly with OMOP CDM's design principles:

1. **Direct Mapping to OMOP**
   - Questions map to OMOP Concepts (CONCEPT table)
   - Responses map to OMOP Values (CONCEPT table)
   - Grid elements map to OMOP Measurements (MEASUREMENT table)
   - All mappings use standard OMOP concept IDs

2. **Observation Structure**
   - Questions become OMOP Observations
   - Responses become OMOP Values
   - Grid questions map to OMOP Measurements
   - Maintains temporal relationships

3. **Vocabulary Integration**
   - Uses OMOP's standard vocabularies
   - Supports SNOMED CT, LOINC, RxNorm, etc.
   - Enables cross-vocabulary mapping
   - Maintains concept hierarchies

4. **Data Quality**
   - Enforces standard concept usage
   - Validates against OMOP vocabularies
   - Maintains data consistency
   - Supports quality checks

### OMOP Mapping Support

QuestSQL provides comprehensive support for mapping questionnaire elements to specific OMOP CDM domains and vocabularies:

1. **Domain-Specific Mapping**
   - **Condition/Disease Questions**
     ```sql
     -- Example: Diabetes screening question
     INSERT INTO questions (
         questionnaire_id,
         question_text,
         question_type,
         concept_id,
         domain_id
     ) VALUES (
         1,
         'Have you been diagnosed with diabetes?',
         'multiple_choice',
         201820,  -- Diabetes mellitus concept
         'Condition'
     );
     ```

   - **Measurement Questions**
     ```sql
     -- Example: Blood pressure measurement
     INSERT INTO questions (
         questionnaire_id,
         question_text,
         question_type,
         concept_id,
         domain_id
     ) VALUES (
         1,
         'What is your blood pressure?',
         'grid',
         3004249,  -- Blood pressure concept
         'Measurement'
     );
     ```

   - **Drug/Medication Questions**
     ```sql
     -- Example: Medication adherence
     INSERT INTO questions (
         questionnaire_id,
         question_text,
         question_type,
         concept_id,
         domain_id
     ) VALUES (
         1,
         'Are you taking your prescribed medications?',
         'multiple_choice',
         4023213,  -- Medication adherence concept
         'Drug'
     );
     ```

2. **Vocabulary-Specific Development**
   - **SNOMED CT Questions**
     ```sql
     -- Example: Pain assessment using SNOMED
     INSERT INTO questions (
         questionnaire_id,
         question_text,
         question_type,
         concept_id,
         vocabulary_id
     ) VALUES (
         1,
         'Rate your pain level',
         'grid',
         36714913,  -- Pain severity concept
         'SNOMED'
     );
     ```