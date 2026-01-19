with 

source as (

    select * from {{ source('lightning_step_census_admissions', 'table_stafflocations') }}

),

renamed as (

    select
        created_at_table_stafflocations as created_at,
        datedoc_table_stafflocations as datedoc,
        datestart_table_stafflocations as datestart,
        datestop_table_stafflocations as datestop,
        eie_table_stafflocations as eie,
        id_table_stafflocations as staff_locations_id,
        isactive_table_stafflocations as isactive,
        isprimary_table_stafflocations as isprimary,
        location_id_table_stafflocations as location_id,
        luby_id_table_stafflocations as luby_id,
        name_table_stafflocations as facility_name,
        precog_delta_key_table_stafflocations as precog_delta_key,
        staff_id_table_stafflocations as staff_id,
        table_stafflocations_precog_key as precog_key,
        updated_at_table_stafflocations as updated_at,
        precog_delta_version_table_stafflocations as precog_delta_version

    from source

)

select * from renamed