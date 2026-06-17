# Transparency

Audit and provenance trail for the project, so variables and models can be traced back to
the raw OSC source data without reading the code.

- [`variable_registry.md`](variable_registry.md) — every variable created in the pipeline,
  its source OSC category, which entity types it exists for, and (to be filled by hand) its
  OSC-glossary definition.
- [`model_registry.md`](model_registry.md) — every statistical model / estimation, its
  specification, sample, and the source variables it depends on.

These files are **hand-maintained**. When `code/02_clean.R` (variables) or
`code/04_analysis.R` and later scripts (models) change, update the matching registry rows in
the **same commit** so the trail never drifts from what the code actually produces.
