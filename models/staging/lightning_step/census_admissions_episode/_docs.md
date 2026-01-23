{% docs stg_lightning_step__admissions %}
**Model:** stg_lightning_step__admissions
**Layer:** staging
**Grain:** 1:1 with source row
**Purpose:** This table is used to track admissions data in LightningStep.

**Inputs:**
- `lightning_step_census_admissions -> table_admissions`
    - Key Column(s): id_table_admissions, dcreason_table_admissions, dctype_table_admissions

**Core logic (TL;DR):**
- rename, type casting, light null handling; no business rules

**Outputs (key columns):**
- `id` - Primary key
- `dctype_id` - Discharge type
- `dcreason` - Discharge reason

**Quality & Contracts:**
- Tests: `not_null(id, dctype_id, dcreason)`, `unique(id, dctype_id, dcreason)`.
- Constraints/Contracts: enforced = false; Need to enforce when it's set up properly.

**Freshness / Latency:**
- Expected refresh: daily.

**Security / PHI:**
- PHI/PII? yes. Need to mask.

**Ownership:**
- Owner team: Data Department
- Owner email: datadepartment@ocdanxietycenters.com
- SME (optional): Amy Brown (Senior VP Operations)

**Downstream consumers:**
- fct_admissions

**Known edge cases:**
- N/A

**Change log (brief):**
- 1/23/2026: initial version; INITIAL_NOTES.
- DATE: CHANGES.
{% enddocs %}


{% docs stg_lightning_step__users %}
**Model:** stg_lightning_step__users
**Layer:** staging
**Grain:** 1:1 with source row
**Purpose:** Raw Lightning Step user rows (emails, names, titles, activity flags).

**Inputs:**
- `lightning_step_census_admissions -> table_users`
    - Key Column(s): id_table_users

**Core logic (TL;DR):**
- rename, type casting, light null handling; no business rules

**Outputs (key columns):**
- `user_id` - User ID

**Quality & Contracts:**
- Tests: `not_null(user_id)`, `unique(user_id)`.
- Constraints/Contracts: enforced = true.

**Freshness / Latency:**
- Expected refresh: daily.

**Security / PHI:**
- PHI/PII? no.

**Ownership:**
- Owner team: Data Department
- Owner email: datadepartment@ocdanxietycenters.com

**Downstream consumers:**
- dim_staff

**Known edge cases:**
- N/A

**Change log (brief):**
- 1/23/2026: initial version; INITIAL_NOTES.
- DATE: CHANGES.
{% enddocs %}


{% docs stg_lightning_step__staff_locations %}
**Model:** stg_lightning_step__staff_locations
**Layer:** staging
**Grain:** 1:1 with source row
**Purpose:** Raw staff-facility rows from Lightning Step (lightly typed only).

**Inputs:**
- `lightning_step_census_admissions -> table_stafflocations`
    - Key Column(s): staff_id, facility_id, is_primary

**Core logic (TL;DR):**
- rename, type casting, light null handling; no business rules

**Outputs (key columns):**
- `staff_id` - The ID of the user (which we eventually limit to staff members)
- `facility_id` - The facility ID (business logic uses term "facility")
- `is_primary` - Is facility the user's primary facility?

**Quality & Contracts:**
- Tests: `not_null(staff_id, facility_id, is_primary)`, `accepted_values(is_primary)`.
- Constraints/Contracts: enforced = true.

**Freshness / Latency:**
- Expected refresh: daily.

**Security / PHI:**
- PHI/PII? no.

**Ownership:**
- Owner team: Data Department
- Owner email: datadepartment@ocdanxietycenters.com

**Downstream consumers:**
- dim_staff

**Known edge cases:**
- There can be deleted users without cascades

**Change log (brief):**
- 1/23/2026: initial version; INITIAL_NOTES.
- DATE: CHANGES.
{% enddocs %}


