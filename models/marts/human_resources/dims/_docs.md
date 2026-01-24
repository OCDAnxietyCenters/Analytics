{% docs dim_staff %}
**Model:** dim_staff  
**Layer:** mart (human_resources)  
**Grain:** One row per active EMR user_id (latest attributes).  
**Purpose:** Canonical staff dimension used across clinical analytics and audit facts.

**Inputs:**  
- `int_lightning_step__users_current` - latest user attributes (email, title, role, is_active).  
- `int_lightning_step__staff_primary_facility` - resolved primary facility id/name.  

**Core logic**
- Join current user to current primary facility; prefer latest timestamps.
- Normalize names with {% raw %}`{{ name_norm('name') }}`{% endraw %} for resilient joins.
- Emit: `staff_id`, `name`, `name_norm`, `email`, `title`, `role`, `is_active`,
  `primary_facility_id`, `primary_facility`.

**Quality & Contracts:**  
- `unique(staff_id)`, `not_null(staff_id)`, `relationships(facility_id → dim_facility.facility_id)`.  
- Contract enforced: true.

**Freshness:** Daily (EMR sync nightly), expected latency < 2 hours.

**Security / PHI:** No direct PHI; contains staff identifiers (internal).

**Ownership:** Data Department — datadepartment@ocdanxietycenters.com

**Downstream:** audit facts, coverage, therapist scorecards.

**Known edge cases:** Orphan facility links when EMR deletes users without cascades; handled upstream in `int_*_orphans`.
{% enddocs %}


{% docs dim_staff__staff_name_norm %}
Normalized (lowercased, punctuation-stripped, space-collapsed) staff name used for resilient joins when `staff_id` is missing. Not unique across all time; prefer `staff_id` when available.
{% enddocs %}