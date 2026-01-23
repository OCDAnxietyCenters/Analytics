with 

source as (

    select * from {{ source('lightning_step_locations', 'table_locations') }}

),

renamed as (

    select
        accept_assignment_table_locations as accept_assignment,
        billpublicname_table_locations as billpublicname,
        created_at_table_locations as created_at,
        datestart_table_locations as datestart,
        default_list_ca_table_locations as default_list_ca,
        defaultclientcashps_id_table_locations as defaultclientcashps_id,
        description_table_locations as description,
        dosespot_id_table_locations as dosespot_id,
        eie_table_locations as eie,
        entity_id_table_locations as entity_id,
        excludefromautoloc_table_locations as excludefromautoloc,
        excludefromgroups_table_locations as excludefromgroups,
        ext_loc_name_table_locations as ext_loc_name,
        facilityaddress_table_locations as facilityaddress,
        facilitycity_table_locations as facilitycity,
        facilityfax_table_locations as facilityfax,
        facilityphone_table_locations as facilityphone,
        facilitystate_table_locations as facilitystate,
        facilitytype_table_locations as facilitytype,
        facilityzip_table_locations as facilityzip,
        id_table_locations as id,
        irsignoff_id_table_locations as irsignoff_id,
        isactive_table_locations as isactive,
        isattendingprovider_table_locations as isattendingprovider,
        isbhworks_table_locations as isbhworks,
        isbillinginfo_table_locations as isbillinginfo,
        iscard_table_locations as iscard,
        ismentalhealth_table_locations as ismentalhealth,
        isnoclinicalservices_table_locations as isnoclinicalservices,
        isowned_table_locations as isowned,
        ispaytonpi_table_locations as ispaytonpi,
        isprimary_table_locations as isprimary,
        issamm_table_locations as issamm,
        issoberliving_table_locations as issoberliving,
        isstatus_table_locations as isstatus,
        istelehealth_table_locations as istelehealth,
        locationtype_table_locations as locationtype,
        meddir_id_table_locations as meddir_id,
        medfiltertype_table_locations as medfiltertype,
        multipletaxonomies_table_locations as multipletaxonomies,
        name_table_locations as name,
        orgname_table_locations as orgname,
        orgshortname_table_locations as orgshortname,
        paytosame_table_locations as paytosame,
        paytostate_table_locations as paytostate,
        paytozip_table_locations as paytozip,
        precog_delta_key_table_locations as precog_delta_key,
        sfname_table_locations as sfname,
        slname_table_locations as slname,
        staff_id_table_locations as staff_id,
        table_locations_precog_key,
        tz_table_locations as tz,
        updated_at_table_locations as updated_at,
        use_alt_address_table_locations as use_alt_address,
        precog_delta_version_table_locations as precog_delta_version

    from source

)

select * from renamed