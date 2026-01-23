with 

source as (

    select * from {{ source('lightning_step_census_admissions', 'table_admissions') }}

),

renamed as (

    select
        datedischarge_table_admissions as datedischarge,
        dcreason_table_admissions as dcreason,
        dctype_table_admissions as dctype,
        eie_table_admissions as eie,
        episode_id_table_admissions as episode_id,
        fname_table_admissions as fname,
        id_table_admissions as id,
        lname_table_admissions as lname,
        location_id_table_admissions as location_id,
        mrn_table_admissions as mrn,
        program_table_admissions as program,
        updated_at_table_admissions as updated_at,


    from source

)

select * from renamed