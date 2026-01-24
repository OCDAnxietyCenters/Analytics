-- macros/dev_cleanup.sql

{# ===============================
   dev_cleanup_report
   Lists candidate orphans in a developer’s schemas vs current manifest
   DOES NOT DROP anything.

   Args:
     database        : target database (e.g. 'ANALYTICS')
     base            : base schema prefix (e.g. 'dbt_aaronjpeterson')
     include         : list of suffixes -> schemas checked: base + '_' + suffix
                       default ['staging','int','marts','snapshots']
     include_types   : which TABLE_TYPE values to include (Snowflake):
                       ['BASE TABLE','VIEW','MATERIALIZED VIEW']
     whitelist       : list[str] of 'SCHEMA.OBJECT' (case-insensitive)
     whitelist_table : {database: 'ANALYTICS', schema: 'ADMIN', table: 'DEV_CLEAN_WHITELIST'}
                       with column names: OBJECT_TYPE, DATABASE_NAME, SCHEMA_NAME, OBJECT_NAME
     show            : 'extra' (default) or 'all'

   Examples:
     List candidates (Output appears in the job/run logs and is also returned as a JSON list):
     dbt run-operation dev_cleanup_report --args "{\"database\":\"ANALYTICS\",\"base\":\"dbt_aaronjpeterson\",\"include\":[\"staging\",\"int\",\"marts\",\"snapshots\"]}"

     Add items to the whitelist table to suppress them:
     insert into ANALYTICS.ADMIN.DEV_CLEAN_WHITELIST (object_type, database_name, schema_name, object_name, note, expires_at) values ('VIEW','ANALYTICS','DBT_AARONJPETERSON_STAGING','OLD_TMP_VIEW','ok to ignore', null);

     Generate DROP SQL (copy/paste if/when you’re ready):
     dbt run-operation dev_cleanup_drop_sql --args "{\"database\":\"ANALYTICS\",\"base\":\"dbt_aaronjpeterson\"}"
================================ #}
-- macros/dev_cleanup.sql

{% macro dev_cleanup_report(database, base, include=['staging','int','marts','snapshots'], include_types=['BASE TABLE','VIEW','MATERIALIZED VIEW'], whitelist=[], whitelist_table={}, show='extra') %}
  {# ----- schemas to scan ----- #}
  {%- set schemas = [] -%}
  {%- for sfx in include -%}
    {%- do schemas.append(base ~ '_' ~ sfx) -%}
  {%- endfor -%}

  {# ----- build a single-quoted IN list for TABLE_TYPE ----- #}
  {%- set include_types_u = include_types | map('upper') | list -%}
  {%- set include_types_sql = "'" ~ include_types_u | join("','") ~ "'" -%}

  {# ----- live objects from INFORMATION_SCHEMA.TABLES ----- #}
  {%- set live = [] -%}
  {%- for sc in schemas %}
    {%- set sql = (
      "select upper(table_schema) as schema_name, "
      "       upper(table_name)   as name, "
      "       upper(table_type)   as kind "
      "from " ~ adapter.quote(database) ~ ".information_schema.tables "
      "where upper(table_schema)=upper('" ~ sc ~ "') "
      "  and upper(table_type) in (" ~ include_types_sql ~ ")"
    ) -%}
    {%- set df = run_query(sql) -%}
    {%- if df is not none and df.columns|length > 0 -%}
      {%- for r in df.rows -%}
        {%- do live.append({'schema': r[0], 'name': r[1], 'kind': r[2]}) -%}
      {%- endfor -%}
    {%- endif -%}
  {%- endfor -%}

  {# ----- expected from manifest (normalize to UPPER) ----- #}
  {%- set expected = [] -%}
  {%- for node in graph.nodes.values()
         | selectattr('resource_type','in',['model','snapshot'])
         | selectattr('package_name','equalto', project_name) -%}
    {%- if node.database == database and (node.schema|upper in schemas | map('upper') | list) -%}
      {%- do expected.append({'schema': node.schema|upper, 'name': (node.alias if node.alias else node.name)|upper}) -%}
    {%- endif -%}
  {%- endfor -%}

  {# ----- optional whitelist (inline + table) ----- #}
  {%- set whitelist_set = whitelist | map('upper') | list -%}
  {%- if whitelist_table and whitelist_table.get('database') and whitelist_table.get('schema') and whitelist_table.get('table') -%}
    {%- set wsql = (
      "select upper(schema_name)||'.'||upper(object_name) as key "
      "from " ~ adapter.quote(whitelist_table['database']) ~ "." ~ adapter.quote(whitelist_table['schema']) ~ "." ~ adapter.quote(whitelist_table['table'])
    ) -%}
    {%- set wdf = run_query(wsql) -%}
    {%- if wdf is not none and wdf.columns|length > 0 -%}
      {%- for r in wdf.rows -%}
        {%- do whitelist_set.append(r[0]) -%}
      {%- endfor -%}
    {%- endif -%}
  {%- endif -%}

  {# ----- extras (live - expected) minus whitelist ----- #}
  {%- set extras = [] -%}
  {%- for o in live -%}
    {%- set exists = expected | selectattr('schema','equalto', o.schema) | selectattr('name','equalto', o.name) | list -%}
    {%- if exists | length == 0 and (o.schema ~ '.' ~ o.name) not in whitelist_set -%}
      {%- do extras.append(o) -%}
    {%- endif -%}
  {%- endfor -%}

  {{ log('--- dev_cleanup_report ---', info=True) }}
  {{ log('Database: ' ~ database, info=True) }}
  {{ log('Schemas: ' ~ (schemas | map('upper') | join(', ')), info=True) }}

  {{ log('Extras (candidates to drop):', info=True) }}
  {%- if extras | length == 0 -%}
    {{ log('  (none)', info=True) }}
  {%- else -%}
    {%- for o in extras %}{{ log('  ' ~ o.schema ~ '.' ~ o.name ~ ' (' ~ o.kind ~ ')', info=True) }}{%- endfor -%}
  {%- endif -%}

  {{ return(extras) }}
{% endmacro %}




{# ===============================
   dev_cleanup_drop_sql
   Emits DROP statements for the current candidates (no execute)
================================ #}
{% macro dev_cleanup_drop_sql(database, base, include=['staging','int','marts','snapshots'], include_types=['BASE TABLE','VIEW','MATERIALIZED VIEW'], whitelist=[], whitelist_table={}) %}
  {%- set extras = call('dev_cleanup_report',
                        database=database,
                        base=base,
                        include=include,
                        include_types=include_types,
                        whitelist=whitelist,
                        whitelist_table=whitelist_table,
                        show='extra') -%}
  {%- if extras | length == 0 -%}
    {{ log('-- nothing to drop', info=True) }}
    {{ return('-- nothing to drop') }}
  {%- endif -%}

  {%- set stmts = [] -%}
  {%- for o in extras -%}
    {%- set fq = adapter.quote(database) ~ '.' ~ adapter.quote(o.schema) ~ '.' ~ adapter.quote(o.name) -%}
    {%- if o.kind in ['VIEW','MATERIALIZED VIEW'] -%}
      {%- do stmts.append('drop view if exists ' ~ fq ~ ';') -%}
    {%- else -%}
      {%- do stmts.append('drop table if exists ' ~ fq ~ ';') -%}
    {%- endif -%}
  {%- endfor -%}
  {{ log(stmts | join('\n'), info=True) }}
  {{ return(stmts | join('\n')) }}
{% endmacro %}
