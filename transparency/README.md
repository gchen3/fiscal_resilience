# Transparency

Audit and provenance trail for the project, so variables and models can be traced back to
the raw OSC source data without reading the code.

- [`variable_registry.md`](variable_registry.md) - every variable created in the pipeline,
  its source OSC category, which entity types it exists for, and its OSC-glossary definition
  where available.
- [`main_variable_registery.md`](main_variable_registery.md) - concise construction notes
  for the main fiscal-resilience dependent variables.
- [`model_registry.md`](model_registry.md) - every statistical model / estimation, its
  specification, sample, and the source variables it depends on.

These files are **hand-maintained**. When variable-producing scripts (`code/20_clean.R`,
`code/40_construct_resilience.R`, `code/45_construct_predictors.R`) or model scripts
(`code/70_model_main.R`, `code/75_model_robustness.R`) change, update the matching registry
rows in the **same commit** so the trail never drifts from what the code actually produces.
