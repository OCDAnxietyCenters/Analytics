{{ config(materialized='view', contract={'enforced': true}) }}

with src as (
  select * from {{ source('lightning_step_census_admissions', 'table_stafflocations') }}
)
select
  staff_id_table_stafflocations       as staff_id,
  location_id_table_stafflocations    as facility_id,
  trim(name_table_stafflocations)     as facility_name,
  to_boolean(isprimary_table_stafflocations) as is_primary,
  to_boolean(isactive_table_stafflocations)  as is_active,
  -- keep as text for INT parse
  to_varchar(updated_at_table_stafflocations) as updated_at_text,
  to_varchar(datedoc_table_stafflocations)    as datedoc_text
from src
