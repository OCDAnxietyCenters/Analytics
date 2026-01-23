{% docs int_ls__staff_facilities_dedup %}
**Model:** int_lightning_step__staff_facilities_dedup  
**Grain:** 1 row per *(staff_id, facility_id)*  
**Purpose:** Remove duplicate Lightning Step staff-location rows and standardize flags for downstream selection.

**Inputs**
- `stg_lightning_step__staff_locations` (raw staff↔facility rows, lightly typed)

**Core logic**
- Deduplicate by `(staff_id, facility_id)` preferring the most recent `updated_at_ntz`, then `datedoc_ntz`, then `facility_name`.
- Carry `is_primary` and `is_active` flags forward as booleans.

**Data quality**
- `not_null(staff_id)`, `not_null(facility_id)`
- `accepted_values(is_primary, [true,false])`; `accepted_values(is_active, [true,false])`

**Downstream**
- `int_lightning_step__staff_primary_facility`
{% enddocs %}

{% docs int_ls__staff_primary_facility %}
**Model:** int_lightning_step__staff_primary_facility  
**Grain:** 1 row per *staff_id*  
**Purpose:** Pick a single “primary” facility per staff member.

**Inputs**
- `int_lightning_step__staff_facilities_dedup`

**Selection rules**
1) Prefer rows with `is_primary = TRUE`.  
2) Tie-break on most recent `updated_at_ntz`, then `facility_name`.

**Outputs**
- `staff_id`, `primary_facility_id`, `primary_facility`, `primary_facility_updated_at_ntz`

**Downstream**
- `int_lightning_step__staff_facilities_valid`, `int_lightning_step__staff_facilities_orphans`, `dim_staff`
{% enddocs %}

{% docs int_ls__staff_facilities_valid %}
**Model:** int_lightning_step__staff_facilities_valid  
**Grain:** 1 row per *staff_id*  
**Purpose:** Keep only staff who (a) have a resolved primary facility and (b) have a current user profile.

**Inputs**
- `int_lightning_step__users_current`
- `int_lightning_step__staff_primary_facility`
- `int_lightning_step__staff_facilities_dedup` (to surface latest facility_name)

**Core logic**
- Join `users_current` to `primary_facility` on `staff_id`.
- Include latest facility attributes and selected user attributes (email, name, title, role, is_active).

**Data quality**
- `unique(staff_id)`; relationships `staff_id -> users_current.user_id`

**Downstream**
- `dim_staff`, coverage and audit facts
{% enddocs %}

{% docs int_ls__staff_facilities_orphans %}
**Model:** int_lightning_step__staff_facilities_orphans  
**Grain:** 1 row per *(staff_id, primary_facility_id)* that is missing from users_current  
**Purpose:** Identify staff who have a primary facility but **no** current user record (e.g., EMR deletions without cascade).

**Inputs**
- `int_lightning_step__staff_primary_facility`
- `int_lightning_step__users_current`

**Usage**
- Monitor as **WARN**. Investigate and correct in source/ETL when rows appear.

**Downstream**
- Data quality dashboards / alerts
{% enddocs %}

{% docs int_ls__users_current %}
**Model:** int_lightning_step__users_current  
**Grain:** 1 row per *user_id* (latest attributes)  
**Purpose:** Provide the authoritative, deduplicated user profile for joins.

**Inputs**
- `stg_lightning_step__users`

**Core logic**
- Parse `updated_at_text` → `updated_at_ntz`.
- Deduplicate by `user_id`, taking the most recent `updated_at_ntz` (then `name` for deterministic ties).

**Columns**
- `user_id`, `email`, `name`, `title`, `role`, `is_active`, `updated_at_ntz`

**Downstream**
- All INT models that need staff attributes; `dim_staff`; audit facts
{% enddocs %}

{% docs col__is_active_bool %}
Boolean from EMR indicating if the record is active at source time. This is a *current-state* flag (not historical).
{% enddocs %}
