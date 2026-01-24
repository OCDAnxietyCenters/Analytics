{{ config(materialized='view') }}

-- Valid staff/facility records: staff exists in users_current AND we can
-- join to the deduped facility row that matches their primary facility id.
-- Includes a normalized name for downstream use.

with base as (
  select
    p.staff_id,
    p.primary_facility,
    p.primary_facility_id,
    p.primary_facility_updated_at_ntz,

    u.user_id,
    u.email,
    u.name,
    KPIS.UTIL.NAME_NORM(u.name)  as name_norm,   -- macro is fine to use here
    u.title,
    u.role,
    u.is_active
  from {{ ref('int_lightning_step__staff_primary_facility') }} as p
  join {{ ref('int_lightning_step__users_current') }}          as u
    on u.user_id = p.staff_id
)

select
  b.staff_id,
  b.user_id,
  b.email,
  b.name,
  b.name_norm,
  b.title,
  b.role,
  b.is_active,
  b.primary_facility,
  b.primary_facility_id,
  b.primary_facility_updated_at_ntz
from base as b
join {{ ref('int_lightning_step__staff_facilities_dedup') }} as sl
  on sl.staff_id   = b.staff_id
 and sl.facility_id = b.primary_facility_id
