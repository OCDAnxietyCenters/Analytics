{% macro name_norm(expr) -%}
  KPIS.UTIL.NAME_NORM({{ expr }})
{%- endmacro %}
