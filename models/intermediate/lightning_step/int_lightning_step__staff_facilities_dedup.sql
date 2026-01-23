{{ config(materialized='view') }}

with base as (
  select
    staff_id,
    facility_id,
    facility_name,
    is_primary,
    is_active,
    try_to_timestamp_ntz(updated_at_text) as updated_at_ntz,
    try_to_timestamp_ntz(datedoc_text)    as datedoc_ntz
  from {{ ref('stg_lightning_step__staff_locations') }}
),
dedup as (
  select *,
         row_number() over (
           partition by staff_id, facility_id
           order by updated_at_ntz desc nulls last,
                    datedoc_ntz desc nulls last,
                    facility_name
         ) as rn
  from base
)
select
  staff_id,
  facility_id,
  facility_name,
  is_primary,
  is_active,
  updated_at_ntz,
  datedoc_ntz
from dedup
where rn = 1
