{{ config(materialized='view') }}

with base as (
  select
    user_id,
    email,
    name,
    title,
    role,
    is_active,
    try_to_timestamp_ntz(updated_at_text) as updated_at_ntz
  from {{ ref('stg_lightning_step__users') }}
),
dedup as (
  select *,
         row_number() over (
           partition by user_id
           order by updated_at_ntz desc nulls last, name
         ) as rn
  from base
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
