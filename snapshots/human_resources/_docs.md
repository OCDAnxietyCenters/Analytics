{% docs staff_scd %}
History table for staff attributes. Each change in the tracked fields produces a
new row with `dbt_valid_from`/`dbt_valid_to`. Use `dbt_valid_to is null` for the
current record; join to facts by the appropriate as-of time when needed.
{% enddocs %}
