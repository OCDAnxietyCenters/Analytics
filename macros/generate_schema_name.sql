-- macros/generate_schema_name.sql
{% macro generate_schema_name(custom_schema_name, node) -%}
  {% set base = target.schema %}
  {% if custom_schema_name %}
    {{ base ~ '_' ~ custom_schema_name }}
  {% else %}
    {{ base }}
  {% endif %}
{%- endmacro %}
