{# ===============================
   staff_scd_sql
   - To take the snapshot manually:
        dbt snapshot --select staff_scd
================================ #}

{% snapshot staff_scd %}

{{
  config(
    unique_key = 'staff_id',
    strategy   = 'check',
    check_cols = [
      'name','name_norm','email','title','role','is_active','primary_facility','primary_facility_id'
    ],
  )
}}

select
  s.staff_id,
  s.name,
  s.name_norm,
  s.email,
  s.title,
  s.role,
  s.is_active,
  s.primary_facility,
  s.primary_facility_id
from {{ ref('int_lightning_step__staff_facilities_valid') }} as s

{% endsnapshot %}
