{{ config(materialized='view', contract={'enforced': true}) }}

with src as (
  select * from {{ source('lightning_step_census_admissions', 'table_users') }}
)
select
  id_table_users                   as user_id,
  lower(trim(email_table_users))   as email,
  trim(name_table_users)           as name,
  lower(trim(title_table_users))   as title,
  lower(trim(role_table_users))    as role,
  -- keep raw form; coerce lightly (no try_cast on same type)
  to_boolean(isactive_table_users) as is_active,
  -- keep as text; we’ll parse once in INT
  to_varchar(updated_at_table_users) as updated_at_text
from src
