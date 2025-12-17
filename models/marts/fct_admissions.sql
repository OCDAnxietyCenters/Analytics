with enriched_admissions as (
    select * from {{ ref('int_admissions_enriched') }}
)

, renamed_filtered as (
    select
        episode_id
        , mrn
        , name
        , program
        , fname
        , lname
        , datedischarge
        , dctype
        , dcreason
        , payor
        , pricouns
    from enriched_admissions
    where
        fname is not null
        and fname not ilike '%Test%'
        and lname not ilike '%Test%'
        and dctype <> 'Transfer'
        and coalesce(eie, 0) <> 1
)

, deduplicated as (
    select *
    from renamed_filtered
    qualify row_number() over (
        partition by episode_id
        order by datedischarge desc
    ) = 1
)

select * from deduplicated