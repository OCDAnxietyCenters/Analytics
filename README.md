# Analytics (dbt)

**A dbt project for transforming and modeling data from Lightning Step EMR and other sources for OCD Anxiety Centers analytics.**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Data Sources](#data-sources)
- [Architecture & Data Flow](#architecture--data-flow)
- [Models](#models)
- [dbt Styling Guide](#dbt-styling-guide)
- [Macros](#macros)
- [Snapshots](#snapshots)
- [Development](#development)
- [Testing & Quality](#testing--quality)
- [Deployment](#deployment)
- [Documentation](#documentation)
- [Support & Contacts](#support--contacts)

---

## Overview

### Domains
- **Lightning Step (EMR)**: Electronic Medical Records data including admissions, census, users, and staff locations
- **Human Resources**: Staff dimension tables and SCD tracking
- **Clinical KPIs**: Key performance indicators for clinical operations

### Environments
- **Development**: dbt Cloud development environment (per-developer schemas, e.g. `dbt_<username>_staging`, `dbt_<username>_int`)
- **Production**: dbt Cloud managed deployments

### Technology Stack
- **dbt Cloud**: Data transformation (development and deployment; no local dbt Core or `profiles.yml`)
- **Data Warehouse**: Snowflake (database: `ANALYTICS`)
- **Source Database**: `PRECOG` (Lightning Step EMR data)
- **Packages**: 
  - `dbt-labs/dbt_utils` (v1.3.2)
  - `dbt-labs/codegen` (v0.14.0)

---

## Project Structure

```
Analytics/
├── analyses/              # Ad-hoc analysis queries
├── macros/                # Reusable SQL macros
│   ├── dev_cleanup.sql   # Development schema cleanup utilities
│   ├── generate_schema_name.sql
│   ├── name_norm.sql     # Name normalization utility
│   └── debug_print_relation.sql
├── models/                # dbt models (SQL transformations)
│   ├── staging/           # Raw → lightly typed
│   │   └── lightning_step/
│   ├── intermediate/      # Cleaned, joined, deduplicated
│   │   └── lightning_step/
│   ├── marts/             # Business-ready models
│   │   ├── fct_admissions.sql
│   │   └── human_resources/
│   ├── legacy/            # Legacy queries (reference)
│   └── docs/              # Model documentation
├── snapshots/             # Slowly Changing Dimensions (SCD)
│   └── human_resources/
├── seeds/                 # Static reference data
├── tests/                 # Custom data tests
├── dbt_project.yml        # Project configuration
├── packages.yml           # dbt package dependencies
└── README.md              # This file
```

---

## Data Sources

### Lightning Step EMR

**Source Database**: `PRECOG`  
**Source Schema**: `ls_census_admissions_episode_lightning_step_oac`

#### Tables

1. **`table_admissions`**
   - **Description**: Patient admissions information
   - **Key Columns**: `id_table_admissions`, `episode_id_table_admissions`, `mrn_table_admissions`
   - **Freshness**: Daily refresh expected
   - **Contains PHI**: Yes

2. **`table_census`**
   - **Description**: Census information linked to episodes
   - **Key Columns**: `episode_id_table_census`, `payor_table_census`, `pricouns_table_census`
   - **Freshness**: Daily refresh expected

3. **`table_users`**
   - **Description**: User directory from EMR (staff and other users)
   - **Key Columns**: `id_table_users`, `email_table_users`, `name_table_users`
   - **Freshness**: 
     - Warn after: 48 hours
     - Error after: 72 hours
   - **Loaded At Field**: `updated_at_table_users`
   - **Contains PHI**: No

4. **`table_stafflocations`**
   - **Description**: Staff ↔ facility assignments
   - **Key Columns**: `staff_id_table_stafflocations`, `location_id_table_stafflocations`, `isprimary_table_stafflocations`
   - **Freshness**: 
     - Warn after: 48 hours
     - Error after: 72 hours
   - **Loaded At Field**: `updated_at_table_stafflocations`
   - **Contains PHI**: No

**Source Schema**: `LS_ATTENDANCE_LIGHTNING_STEP_OAC`

5. **`table_locations`**
   - **Description**: Facility/location data
   - **Key Columns**: `ID_TABLE_LOCATIONS`, `NAME_TABLE_LOCATIONS`
   - **Freshness**: Daily refresh expected

---

## Architecture & Data Flow

### Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SOURCE DATA                          │
│              (PRECOG Database)                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  STAGING LAYER                          │
│  • Rename columns                                       │
│  • Type casting                                         │
│  • Light null handling                                  │
│  • No business rules                                    │
│  Naming: stg_*                                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              INTERMEDIATE LAYER                         │
│  • Cleaned data                                         │
│  • Joined tables                                        │
│  • Deduplicated                                         │
│  • Business logic applied                               │
│  Naming: int_*                                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   MARTS LAYER                           │
│  • Business-ready models                                │
│  • Dimensions (dim_*)                                   │
│  • Facts (fct_*)                                        │                                    │
└─────────────────────────────────────────────────────────┘
```

### Schema Organization

- **Staging**: `{target.schema}_staging` (e.g. `dbt_username_staging`)
- **Intermediate**: `{target.schema}_int` (e.g. `dbt_username_int`)
- **Marts**: `{target.schema}_marts` (e.g. `dbt_username_marts`)
- **Snapshots**: `{target.schema}_snapshots` (e.g. `dbt_username_snapshots`)

Schemas are defined by the dbt Cloud connection and `generate_schema_name`; no local configuration.

---

## Models

### Naming Conventions

- **Staging**: `stg_*` - Raw → lightly typed
- **Intermediate**: `int_*` - Cleaned, joined, deduped
- **Marts**: 
  - `dim_*` - Dimension tables
  - `fct_*` - Fact tables

### Staging Models

#### Lightning Step - Census & Admissions

**Location**: `models/staging/lightning_step/census_admissions_episode/`

1. **`stg_lightning_step__admissions`**
   - **Grain**: 1:1 with source row
   - **Purpose**: Lightly typed admissions data
   - **Key Columns**: `id`, `episode_id`, `mrn`, `fname`, `lname`, `datedischarge`, `dctype`, `dcreason`, `location_id`, `eie`
   - **Downstream**: `int_admissions_enriched` → `fct_admissions`
   - **Contains PHI**: Yes

2. **`stg_lightning_step__census`**
   - **Grain**: 1:1 with source row
   - **Purpose**: Census information linked to episodes
   - **Key Columns**: `episode_id`, `payor`, `pricouns`
   - **Downstream**: `int_admissions_enriched` → `fct_admissions`

3. **`stg_lightning_step__users`**
   - **Grain**: 1:1 with source row
   - **Purpose**: Raw user directory from EMR
   - **Key Columns**: `user_id`, `email`, `name`, `title`, `role`, `is_active`, `updated_at`
   - **Downstream**: `int_lightning_step__users_current` → `dim_staff`
   - **Tests**: `not_null(user_id)`, `unique(user_id)`

4. **`stg_lightning_step__staff_locations`**
   - **Grain**: 1:1 with source row
   - **Purpose**: Raw staff-facility assignment rows
   - **Key Columns**: `staff_id`, `facility_id`, `is_primary`, `is_active`, `datedoc`, `updated_at`
   - **Downstream**: `int_lightning_step__staff_facilities_dedup` → `dim_staff`
   - **Tests**: `not_null(staff_id, facility_id, is_primary)`, `accepted_values(is_primary)`

#### Lightning Step - Attendance

**Location**: `models/staging/lightning_step/attendance/`

5. **`stg_lightning_step__locations`**
   - **Grain**: 1:1 with source row
   - **Purpose**: Facility/location reference data
   - **Key Columns**: `id`, `name`
   - **Downstream**: `int_admissions_enriched` → `fct_admissions`

### Intermediate Models

**Location**: `models/intermediate/lightning_step/`

1. **`int_lightning_step__users_current`**
   - **Grain**: 1 row per `user_id` (latest attributes)
   - **Purpose**: Authoritative, deduplicated user profile
   - **Logic**: Deduplicates by `user_id`, taking most recent `updated_at_ntz`
   - **Downstream**: All INT models needing staff attributes, `dim_staff`, audit facts

2. **`int_lightning_step__staff_facilities_dedup`**
   - **Grain**: 1 row per `(staff_id, facility_id)`
   - **Purpose**: Remove duplicate staff-location rows
   - **Logic**: Deduplicates by `(staff_id, facility_id)`, preferring most recent `updated_at_ntz`
   - **Downstream**: `int_lightning_step__staff_primary_facility`

3. **`int_lightning_step__staff_primary_facility`**
   - **Grain**: 1 row per `staff_id`
   - **Purpose**: Select single "primary" facility per staff member
   - **Selection Rules**:
     1. Prefer rows with `is_primary = TRUE`
     2. Tie-break on most recent `updated_at_ntz`, then `facility_name`
   - **Downstream**: `int_lightning_step__staff_facilities_valid`, `dim_staff`

4. **`int_lightning_step__staff_facilities_valid`**
   - **Grain**: 1 row per `staff_id`
   - **Purpose**: Staff with resolved primary facility and current user profile
   - **Logic**: Joins `users_current` to `primary_facility` on `staff_id`
   - **Downstream**: `dim_staff`, coverage and audit facts

5. **`int_lightning_step__staff_facilities_orphans`**
   - **Grain**: 1 row per `(staff_id, primary_facility_id)` missing from `users_current`
   - **Purpose**: Identify orphaned staff records (EMR deletions without cascade)
   - **Usage**: Monitor as WARN; investigate when rows appear
   - **Downstream**: Data quality dashboards/alerts

6. **`int_admissions_enriched`**
   - **Grain**: 1 row per admission episode
   - **Purpose**: Enriched admissions with location and census data
   - **Logic**: Joins admissions → locations → census
   - **Downstream**: `fct_admissions`

### Mart Models

**Location**: `models/marts/`

1. **`fct_admissions`**
   - **Grain**: 1 row per admission episode (deduplicated)
   - **Purpose**: Business-ready admissions fact table
   - **Logic**: 
     - Filters out test records (`fname not ilike '%Test%'`)
     - Excludes transfers (`dctype <> 'Transfer'`)
     - Excludes EIE records (`eie <> 1`)
     - Deduplicates by `episode_id` (most recent `datedischarge`)
   - **Columns**: `episode_id`, `mrn`, `location_name`, `program`, `fname`, `lname`, `datedischarge`, `dctype`, `dcreason`, `payor`, `pricouns`
   - **Materialization**: View

#### Human Resources Marts

**Location**: `models/marts/human_resources/dims/`

2. **`dim_staff`**
   - **Grain**: One row per active EMR `user_id` (latest attributes)
   - **Purpose**: Canonical staff dimension for clinical analytics and audit facts
   - **Source**: `snapshots.staff_scd` where `dbt_valid_to IS NULL`
   - **Columns**: 
     - `staff_id` (stable key)
     - `name`, `name_norm` (normalized for resilient joins)
     - `email`, `title`, `role`
     - `is_active`
     - `primary_facility`, `primary_facility_id`
   - **Tests**: 
     - `not_null(staff_id)`, `unique(staff_id)`
     - `not_null(name, name_norm)`
     - `accepted_values(is_active, [true, false])`
   - **Contract**: Enforced
   - **Freshness**: Daily (EMR sync nightly), expected latency < 2 hours
   - **Downstream**: Audit facts, coverage, therapist scorecards

---

## dbt Styling Guide

This project follows the [dbt styling guide](https://docs.getdbt.com/best-practices/how-we-style/1-how-we-style-our-dbt-models) for consistency and maintainability. Key conventions:

### Fields and Model Names

| Rule | Convention | Example |
|------|------------|---------|
| **Models** | Pluralized | `admissions`, `orders`, `products` |
| **Primary key** | Named `<object>_id` | `admission_id`, `order_id`, `customer_id` |
| **Model names** | Underscores only (no dots) | ✅ `stg_lightning_step__admissions` ❌ `stg.lightning.step.admissions` |
| **Keys** | String data type (where practical) | — |
| **Consistency** | Same field names across models | Use `customer_id` everywhere, not `user_id` in one place |
| **Abbreviations** | Avoid; use full names | ✅ `first_name`, `discharge_reason` ❌ `fname`, `dcreason` |
| **Reserved words** | Avoid as column names | — |
| **Booleans** | Prefix with `is_` or `has_` | `is_active`, `is_primary`, `has_pharmacy` |
| **Timestamps** | `<event>_at`, UTC | `created_at`, `updated_at`, `deleted_at` |
| **Dates** | `<event>_date` | `created_date`, `discharged_date` |
| **Events** | Past tense | `created`, `updated`, `deleted` |
| **Prices** | Decimal currency | `19.99` for $19.99; use `_in_cents` suffix if stored as cents |
| **Naming** | `snake_case` for schema, table, column | — |
| **Terminology** | Business terms over source terms | Use `customer_id` if business calls them customers |
| **Versions** | Suffix `_v1`, `_v2` | `customers_v1`, `customers_v2` |


### Reference

- [How we style our dbt models](https://docs.getdbt.com/best-practices/how-we-style/1-how-we-style-our-dbt-models) — dbt Developer Hub

---

## Macros

**Location**: `macros/`

### `name_norm(expr)`
- **Purpose**: Normalize names for resilient joins
- **Implementation**: Calls `KPIS.UTIL.NAME_NORM()` function
- **Usage**: `{{ name_norm('name') }}`
- **Use Case**: Used in `dim_staff` to create `name_norm` column

### `generate_schema_name(custom_schema_name, node)`
- **Purpose**: Custom schema naming for dbt Cloud development environments
- **Logic**: Prepends `{target.schema}_` to custom schema names
- **Example**: `staging` → `dbt_username_staging`

### `dev_cleanup_report(database, base, include, include_types, whitelist, whitelist_table, show)`
- **Purpose**: Lists candidate orphaned objects in developer schemas vs current manifest
- **Important**: Does NOT drop anything
- **Usage**: Run from dbt Cloud IDE or a dbt Cloud job:
  ```bash
  dbt run-operation dev_cleanup_report --args "{\"database\":\"ANALYTICS\",\"base\":\"dbt_username\",\"include\":[\"staging\",\"int\",\"marts\",\"snapshots\"]}"
  ```
- **Whitelist Support**: Can use inline whitelist or `ADMIN.DEV_CLEAN_WHITELIST` table

### `dev_cleanup_drop_sql(database, base, include, include_types, whitelist, whitelist_table)`
- **Purpose**: Generates DROP SQL statements for orphaned objects (no execution)
- **Usage**: Run from dbt Cloud IDE or a dbt Cloud job:
  ```bash
  dbt run-operation dev_cleanup_drop_sql --args "{\"database\":\"ANALYTICS\",\"base\":\"dbt_username\"}"
  ```
- **Output**: SQL statements to copy/paste when ready to clean up

### `debug_print_relation.sql`
- **Purpose**: Debug utility for printing relation information

---

## Snapshots

**Location**: `snapshots/human_resources/`

### `staff_scd`
- **Type**: Slowly Changing Dimension (Type 2)
- **Strategy**: `check` (tracks changes in specified columns)
- **Unique Key**: `staff_id`
- **Check Columns**: `name`, `name_norm`, `email`, `title`, `role`, `is_active`, `primary_facility`, `primary_facility_id`
- **Source**: `int_lightning_step__staff_facilities_valid`
- **Purpose**: Historical tracking of staff attribute changes
- **Usage**: 
  - Current record: `WHERE dbt_valid_to IS NULL`
  - Historical: Join by appropriate `as-of` time
- **Execution**: Run `dbt snapshot --select staff_scd` from dbt Cloud IDE or via a dbt Cloud job.

---

## Development

All development happens in **dbt Cloud**. There is no local dbt Core setup, no `profiles.yml`, and no local coding.

### Prerequisites

- **dbt Cloud** account and access to this project
- Snowflake access via the dbt Cloud connection (`ANALYTICS`, `PRECOG`)

Connection details are configured in dbt Cloud; packages (`packages.yml`) are installed automatically when you run.

### Working in dbt Cloud

- **IDE**: Edit models, run commands, and view logs in the dbt Cloud IDE.
- **Jobs**: Use dbt Cloud jobs for scheduled runs, snapshots, and tests.
- **Docs**: Use the built-in **Docs** tab in dbt Cloud (no `dbt docs serve` locally).

### Common Commands (dbt Cloud IDE)

```bash
# Run all models
dbt run

# Run specific model
dbt run --select stg_lightning_step__admissions

# Run models with tag
dbt run --select tag:hr

# Run tests
dbt test

# Run tests for specific model
dbt test --select stg_lightning_step__admissions

# Run snapshots
dbt snapshot
dbt snapshot --select staff_scd

# Compile (check syntax)
dbt compile

# List models
dbt list
```

### Development Workflow

1. **Create a branch** (Git integration in dbt Cloud).
2. **Develop in the dbt Cloud IDE** in your dev schema.
3. **Test changes**:
   ```bash
   dbt run --select <your_model>
   dbt test --select <your_model>
   ```
4. **Review docs** in the dbt Cloud **Docs** tab.
5. **Clean up dev schemas** when done (see Schema Cleanup below).

### Schema Cleanup

The `dev_cleanup` macros help find and clean up orphaned objects in development schemas. Run these from the dbt Cloud IDE (or a job):

1. **Report orphaned objects**:
   ```bash
   dbt run-operation dev_cleanup_report --args "{\"database\":\"ANALYTICS\",\"base\":\"dbt_<username>\",\"include\":[\"staging\",\"int\",\"marts\",\"snapshots\"]}"
   ```

2. **Generate DROP SQL** (review before executing):
   ```bash
   dbt run-operation dev_cleanup_drop_sql --args "{\"database\":\"ANALYTICS\",\"base\":\"dbt_<username>\"}"
   ```

3. **Whitelist objects** (if needed), in Snowflake:
   ```sql
   INSERT INTO ANALYTICS.ADMIN.DEV_CLEAN_WHITELIST 
   (object_type, database_name, schema_name, object_name, note, expires_at) 
   VALUES 
   ('VIEW', 'ANALYTICS', 'DBT_USERNAME_STAGING', 'OLD_TMP_VIEW', 'ok to ignore', NULL);
   ```

---

## Testing & Quality

### Test Types

1. **Generic Tests** (defined in `_schema.yml` files):
   - `not_null`: Ensures column is not null
   - `unique`: Ensures column values are unique
   - `accepted_values`: Validates against allowed values
   - `relationships`: Foreign key relationships

2. **Custom Tests**: Located in `tests/` directory

### Model Contracts

Some models enforce contracts (strict column definitions):
- `dim_staff`: Contract enforced
- `fct_admissions`: Contract not enforced (to be enabled)

### Data Quality Monitoring

- **Source Freshness**: Configured in `__sources.yml` files
  - `table_users`: Warn after 48h, error after 72h
  - `table_stafflocations`: Warn after 48h, error after 72h

- **Orphan Detection**: `int_lightning_step__staff_facilities_orphans` model identifies data quality issues

### Running Tests

Run from the dbt Cloud IDE or via dbt Cloud jobs:

```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select stg_lightning_step__admissions

# Run tests with tag
dbt test --select tag:hr

# Run source freshness checks
dbt source freshness
```

---

## Deployment

### Environments

- **Development**: dbt Cloud development environment (per-developer schemas)
- **Production**: dbt Cloud production environment

### Production Deployment

Production runs are managed through dbt Cloud:
1. Changes are merged to `main` (or your production branch)
2. dbt Cloud jobs run on schedule or on merge
3. Models are built in production schemas using the production connection

### Materialization Strategy

- **Default**: Views (configured in `dbt_project.yml`)
- **Staging**: Views
- **Intermediate**: Views
- **Marts**: Views (can be overridden per model)
- **Snapshots**: Tables (automatic)

---

## Documentation

### Viewing Documentation

Use the **Docs** tab in dbt Cloud. Docs are generated from the project and stay in sync with runs; no local `dbt docs generate` or `dbt docs serve` is needed.

### Documentation Structure

- **Model Documentation**: Defined in `_docs.md` and `_schema.yml` files
- **Source Documentation**: Defined in `__sources.yml` files
- **Metrics**: Defined in `models/docs/metrics.md`

### Key Documentation Files

- `models/staging/lightning_step/census_admissions_episode/_docs.md`
- `models/intermediate/lightning_step/_docs.md`
- `models/marts/human_resources/dims/_docs.md`
- `snapshots/human_resources/_docs.md`

---

## Support & Contacts

### Data Department
- **Email**: datadepartment@ocdanxietycenters.com
- **Owner Team**: Data Department
- **Domain**: Analytics & Data Engineering


### Getting Help

1. **Documentation**: Check this README and model `_docs.md` files
2. **dbt Cloud Docs**: Use the **Docs** tab in dbt Cloud for interactive project documentation
3. **Data Department**: Contact via email for questions or issues

---

## Additional Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Cloud](https://www.getdbt.com/product/what-is-dbt-cloud)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [dbt Styling Guide](https://docs.getdbt.com/best-practices/how-we-style/1-how-we-style-our-dbt-models) — How we style our dbt models
- [Snowflake Documentation](https://docs.snowflake.com/)

---

## Project Metadata

- **Project Name**: `analytics`
- **Version**: `1.0.0`
- **dbt Version**: Config version 2
- **Target Database**: `ANALYTICS`
- **Last Updated**: January 2026

---

## License

Internal project for OCD Anxiety Centers.
