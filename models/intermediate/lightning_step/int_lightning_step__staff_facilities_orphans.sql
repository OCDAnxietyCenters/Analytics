{{ config(materialized='view') }}

-- Staff who have a primary facility chosen but no matching user row
select
  p.staff_id,
  p.primary_facility,
  p.primary_facility_id,
  p.primary_facility_updated_at_ntz
from {{ ref('int_lightning_step__staff_primary_facility') }} as p
left join {{ ref('int_lightning_step__users_current') }}     as u
  on u.user_id = p.staff_id
where u.user_id is null
