with admissions as (
    select * from {{ ref('stg_lightning_step__admissions') }}
),

locations as (
    select * from {{ ref('stg_lightning_step__locations') }}
),

census as (
    select * from {{ ref('stg_lightning_step__census') }}
),

joined as (
    select
        admissions.episode_id,
        admissions.mrn,
        locations.name as location_name,
        census.payor,
        census.pricouns,
        admissions.program,
        admissions.fname,
        admissions.lname,
        admissions.datedischarge,
        admissions.dctype,
        admissions.dcreason,
        admissions.eie
        
    from admissions
    left join locations
        on admissions.location_id = locations.id
    left join census
        on admissions.episode_id = census.episode_id
)

select * from joined