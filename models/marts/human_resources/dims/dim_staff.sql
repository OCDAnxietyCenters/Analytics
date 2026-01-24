{{ config(materialized='view', contract={'enforced': true}) }}

/* =============================================================================
   MODEL: dim_staff (current from SCD)
   PURPOSE
     Current snapshot of staff: one row per staff_id, sourced from the
     SCD snapshot where dbt_valid_to IS NULL.
   INPUT
     - snapshots.staff_scd
============================================================================= */

with scd as (
  select
    staff_id,
    name,
    name_norm,
    email,
    title,
    role,
    is_active,
    primary_facility,
    primary_facility_id
  from {{ ref('staff_scd') }}
  where dbt_valid_to is null
)

select *
from scd
