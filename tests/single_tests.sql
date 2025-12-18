with

    source as (
        
        select
            *
        from {{ ref('model') }}

    )

    , final as (


        select
            *
            , current_timestamp as checked_at
        from source
        where
            column_with_current_timestamp > current_timestamp
            or column_with_current_timestamp_n2 > current_timestamp
    )

select * from final