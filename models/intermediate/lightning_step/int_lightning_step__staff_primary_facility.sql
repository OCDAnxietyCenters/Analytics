{{ config(materialized='view') }}

with ranked as (
  select
    s.*,
    row_number() over (
      partition by staff_id
      order by case when is_primary then 1 else 0 end desc,
               updated_at_ntz desc nulls last,
               facility_name
    ) as rn_primary
  from {{ ref('int_lightning_step__staff_facilities_dedup') }} s
  where is_active = true
)
select
  staff_id,
  facility_id    as primary_facility_id,
  facility_name  as primary_facility,
  updated_at_ntz as primary_facility_updated_at_ntz
from ranked
where rn_primary = 1
