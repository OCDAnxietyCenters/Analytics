# Analytics (dbt)
**Domains**: Lightning Step (EMR), HR, Clinical KPIs  
**Environments**: dev → prod (dbt Cloud)  
**Contacts**: Data Department (datadepartment@ocdanxietycenters.com)

## Folders
- models/staging/lightning_step/…
- models/intermediate/lightning_step/…
- models/marts/human_resources/…
- snapshots/human_resources/…

## Naming
- `stg_*` raw → lightly typed
- `int_*` cleaned, joined, deduped
- `dim_*`, `fct_*`, `rpt_*` for marts

## Docs
Generate: `dbt docs generate`  
Serve (local): `dbt docs serve`
