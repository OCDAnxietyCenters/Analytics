{% macro debug_print_relation(model_name) %}
  {%- set node = graph.nodes.values() | selectattr('name', 'equalto', model_name) | list | first -%}
  {%- if not node -%}
    {{ exceptions.raise_compiler_error("Model '" ~ model_name ~ "' not found in graph") }}
  {%- endif -%}

  {%- set rel = adapter.get_relation(
      database=node.database or target.database,
      schema=node.schema or target.schema,
      identifier=node.alias or node.name
  ) -%}

  {{ log("Resolved relation for " ~ model_name ~ ": " ~
          (rel.database ~ '.' ~ rel.schema ~ '.' ~ rel.identifier if rel else
           "(not found, will be created at runtime)"), info=True) }}
{% endmacro %}
