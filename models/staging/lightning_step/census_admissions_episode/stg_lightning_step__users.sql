{{ config(materialized='view', contract={'enforced': true}) }}

with src as (
  select * from {{ source('lightning_step_census_admissions', 'table_users') }}
),

renamed as (
  select
    id_table_users                       as user_id,
    lower(trim(email_table_users))       as email,
    trim(name_table_users)               as name,
    lower(trim(title_table_users))       as title,
    lower(trim(role_table_users))        as role,

    /* robust boolean coercion (0/1/'true'/'false') */
    to_boolean(isactive_table_users)     as is_active,

    /* convert to text first; we'll parse to TS_NTZ once */
    to_varchar(updated_at_table_users)   as updated_at_text
  from src
),

dedup as (
  select
    user_id,
    email,
    name,
    title,
    role,
    is_active,

    /* single parse to TIMESTAMP_NTZ (no try_cast-on-timestamp) */
    try_to_timestamp_ntz(updated_at_text) as updated_at_ntz,

    row_number() over (
      partition by user_id
      order by try_to_timestamp_ntz(updated_at_text) desc nulls last, name
    ) as rn
  from renamed
)

select
  user_id,
  email,
  name,
  title,
  role,
  is_active,
  updated_at_ntz
from dedup
where rn = 1
