# Variable Registry

Hand-maintained audit trail for every variable created in the pipeline. The goal is that
any variable can be traced back to the raw OSC source data without reading the code.

- **Maintenance:** hand-edited. When a variable is added/removed/renamed in
  `code/20_clean.R`, update the matching row here in the same commit.
- **Source data vintage:** NYS OSC local government finance download, fiscal years 1995–2025,
  downloaded 2026-02-04 (see `data/OSC/README.md`).
- **OSC glossary (fill the Definition / Glossary ref columns from here):**
  https://wwe2.osc.state.ny.us/transparency/LocalGov/LocalGovGlossary.cfm

## How these variables are created (shared lineage)

All finance variables below are produced by `generate_finance()` in
[`code/20_clean.R`](../code/20_clean.R) (functions in `code/functions/finance.R`) and merged
into wide entity-year tables by [`code/30_merge.R`](../code/30_merge.R). The lineage is identical for every row, so it is
documented once here rather than repeated per variable:

1. **Raw input:** per-year OSC CSVs in `data/OSC/all_classes_years/<year>_<Class>.csv`
   (City, County, Town, SchoolDistrict), imported by `code/10_import.R`.
2. **Source columns used:** `amount` (the value summed), keyed by `calendar_year`,
   `entity_name`, `municipal_code`; filtered on `financial_statement_segment` /
   `account_code_section` (revenue vs expenditure) and `level_1_category` / `level_2_category`.
3. **Transformation:** rows are filtered to the segment + category, then
   `amount` is **summed** within each `calendar_year × entity_name × municipal_code`.
4. **Naming:** `<entity>_<segment>_<level>_<category>`, e.g.
   `city_exp_L1_general_government`, `school_rev_L2_real_property_taxes`.
   - `entity` ∈ {`city`, `county`, `town`, `school`}
   - `segment` ∈ {`exp` (expenditure), `rev` (revenue)}
   - `level` ∈ {`L1` (OSC `level_1_category`), `L2` (OSC `level_2_category`)}
   - `category` = OSC category label, lowercased, non-alphanumerics → `_`
     (via `clean_var_suffix()`).
5. **Output:** one column per variable in `data/processed_data/<entity>_data_merged.rds`.

Because categories are derived **separately per entity type**, not every variable exists for
every entity. The **Entities** column records where each variable is present.

### Legend
- Entities: **C** = city, **Co** = county, **T** = town, **S** = school district.
- The `Variable` column shows the suffix shared across entities; prepend the entity prefix
  (`city_`, `county_`, `town_`, `school_`) to get the actual column name.
- `Source category` = the OSC `level_1_category` / `level_2_category` value the variable is
  filtered on (lowercased, as stored after cleaning).
- `Definition` / `Glossary ref` = **to be filled by hand** from the OSC glossary (`_TBD_`).

## Identity / total variables

| Variable | Segment | Entities | Definition (OSC glossary) | Glossary ref |
|---|---|---|---|---|
| `expenditures` | all expenditure rows | C/Co/T/S | Total expenditures (sum of all expenditure account rows). | _TBD_ |
| `revenues` | all revenue rows | C/Co/T/S | Total revenues (sum of all revenue account rows). | _TBD_ |

## Expenditures — Level 1

| Variable | Source category (level_1_category) | Entities | Definition (OSC glossary) | Glossary ref |
|---|---|---|---|---|
| `exp_L1_community_services` | community services | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L1_culture_and_recreation` | culture and recreation | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L1_debt_service` | debt service | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L1_economic_development` | economic development | C/Co/T | _TBD_ | _TBD_ |
| `exp_L1_education` | education | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L1_employee_benefits` | employee benefits | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L1_general_government` | general government | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L1_health` | health | C/Co/T | _TBD_ | _TBD_ |
| `exp_L1_other_uses` | other uses | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L1_public_safety` | public safety | C/Co/T | _TBD_ | _TBD_ |
| `exp_L1_sanitation` | sanitation | C/Co/T | _TBD_ | _TBD_ |
| `exp_L1_social_services` | social services | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L1_transportation` | transportation | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L1_utilities` | utilities | C/Co/T | _TBD_ | _TBD_ |

## Expenditures — Level 2

| Variable | Source category (level_2_category) | Entities | Definition (OSC glossary) | Glossary ref |
|---|---|---|---|---|
| `exp_L2_administration` | administration | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_adult_recreation` | adult recreation | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_airports` | airports | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_broadband_improvements` | broadband improvements | Co/T | _TBD_ | _TBD_ |
| `exp_L2_bus_service` | bus service | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_community_college` | community college | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_constituent_services` | constituent services | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_correctional_services` | correctional services | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_county_distribution_of_sales_tax` | county distribution of sales tax | Co/T | _TBD_ | _TBD_ |
| `exp_L2_cultural_services` | cultural services | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_debt_principal` | debt principal | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_development_infrastructure` | development infrastructure | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_disability_insurance` | disability insurance | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_disaster_response` | disaster response | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_drainage` | drainage | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_economic_development_administration` | economic development administration | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_economic_development_grants` | economic development grants | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_education_transportation` | education transportation | S | _TBD_ | _TBD_ |
| `exp_L2_elder_services` | elder services | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_electricity` | electricity | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_emergency_response` | emergency response | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_employment_services` | employment services | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_environmental_services` | environmental services | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_financial_assistance` | financial assistance | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_fire_protection` | fire protection | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_highway_services_to_other_govts` | highway services to other govts | Co/T | _TBD_ | _TBD_ |
| `exp_L2_highways` | highways | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_homeland_security_and_civil_defense` | homeland security and civil defense | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_housing_assistance` | housing assistance | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_instruction` | instruction | Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_instructional_support` | instructional support | S | _TBD_ | _TBD_ |
| `exp_L2_interest_on_debt` | interest on debt | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_judgements` | judgements | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_landfill_closures` | landfill closures | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_library` | library | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_life_insurance` | life insurance | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_losap_miscellaneous` | losap miscellaneous | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_medicaid` | medicaid | C/Co | _TBD_ | _TBD_ |
| `exp_L2_medical_insurance` | medical insurance | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_mental_health_services` | mental health services | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_community_services` | miscellaneous community services | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_cultural_and_recreation` | miscellaneous cultural and recreation | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_economic_development` | miscellaneous economic development | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_education` | miscellaneous education | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_general_government` | miscellaneous general government | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_public_health` | miscellaneous public health | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_public_safety` | miscellaneous public safety | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_sanitation` | miscellaneous sanitation | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_social_services` | miscellaneous social services | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_miscellaneous_transportation` | miscellaneous transportation | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_natural_gas` | natural gas | Co/T | _TBD_ | _TBD_ |
| `exp_L2_natural_resources` | natural resources | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_non_medicaid_medical_assistance` | non medicaid medical assistance | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_operations` | operations | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_police` | police | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_promotion` | promotion | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_public_facilities` | public facilities | C/Co | _TBD_ | _TBD_ |
| `exp_L2_public_health_administration` | public health administration | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_public_health_facilities` | public health facilities | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_public_health_services` | public health services | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_public_safety_administration` | public safety administration | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_pupil_services` | pupil services | S | _TBD_ | _TBD_ |
| `exp_L2_rail_service` | rail service | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_recreation_services` | recreation services | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_refuse_and_garbage` | refuse and garbage | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_retirement_police_fire` | retirement police fire | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_retirement_state_local` | retirement state local | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_retirement_teacher` | retirement teacher | S | _TBD_ | _TBD_ |
| `exp_L2_sewer` | sewer | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_social_security` | social security | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_social_service_administration` | social service administration | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_steam` | steam | C | _TBD_ | _TBD_ |
| `exp_L2_storm_sewer` | storm sewer | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_student_activities` | student activities | S | _TBD_ | _TBD_ |
| `exp_L2_student_census` | student census | S | _TBD_ | _TBD_ |
| `exp_L2_transfers` | transfers | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_transportation_ancillary` | transportation ancillary | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_transportation_facilities` | transportation facilities | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_unclassified_employee_benefits` | unclassified employee benefits | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_unemployment_insurance` | unemployment insurance | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_union_benefits_program` | union benefits program | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_water` | water | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_waterways` | waterways | C/Co/T | _TBD_ | _TBD_ |
| `exp_L2_workers_compensation` | workers compensation | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_youth_recreation` | youth recreation | C/Co/T/S | _TBD_ | _TBD_ |
| `exp_L2_youth_services` | youth services | C/Co | _TBD_ | _TBD_ |
| `exp_L2_zoning_and_planning` | zoning and planning | C/Co/T | _TBD_ | _TBD_ |

## Revenues — Level 1

| Variable | Source category (level_1_category) | Entities | Definition (OSC glossary) | Glossary ref |
|---|---|---|---|---|
| `rev_L1_charges_for_services` | charges for services | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_charges_to_other_governments` | charges to other governments | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_federal_aid` | federal aid | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_other_local_revenues` | other local revenues | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_other_non_property_taxes` | other non property taxes | C/Co/T | _TBD_ | _TBD_ |
| `rev_L1_other_real_property_tax_items` | other real property tax items | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_other_sources` | other sources | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_proceeds_of_debt` | proceeds of debt | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_real_property_taxes_and_assessments` | real property taxes and assessments | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_sales_and_use_tax` | sales and use tax | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_state_aid` | state aid | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L1_use_and_sale_of_property` | use and sale of property | C/Co/T/S | _TBD_ | _TBD_ |

## Revenues — Level 2

| Variable | Source category (level_2_category) | Entities | Definition (OSC glossary) | Glossary ref |
|---|---|---|---|---|
| `rev_L2_bans_redeemed_from_appropriations` | bans redeemed from appropriations | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_city_income_tax` | city income tax | C | _TBD_ | _TBD_ |
| `rev_L2_community_services_charges` | community services charges | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_community_services_fees` | community services fees | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_compensation_for_loss` | compensation for loss | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_culture_and_recreation_charges` | culture and recreation charges | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_culture_and_recreation_fees` | culture and recreation fees | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_debt_service_charges` | debt service charges | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_economic_development_fees` | economic development fees | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_education_charges` | education charges | Co/S | _TBD_ | _TBD_ |
| `rev_L2_education_fees` | education fees | S | _TBD_ | _TBD_ |
| `rev_L2_emergency_telephone_system_surcharge` | emergency telephone system surcharge | Co | _TBD_ | _TBD_ |
| `rev_L2_employee_contributions` | employee contributions | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_community_services` | federal aid community services | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_culture_and_recreation` | federal aid culture and recreation | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_economic_development` | federal aid economic development | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_education` | federal aid education | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_general_government` | federal aid general government | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_health` | federal aid health | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_public_safety` | federal aid public safety | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_sanitation` | federal aid sanitation | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_social_services` | federal aid social services | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_transportation` | federal aid transportation | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_federal_aid_utilities` | federal aid utilities | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_fines` | fines | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_forfeitures` | forfeitures | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_franchises` | franchises | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_gain_from_sale_of_tax_acquired_property` | gain from sale of tax acquired property | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_general_government_charges` | general government charges | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_general_government_fees` | general government fees | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_gifts` | gifts | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_health_charges` | health charges | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_health_fees` | health fees | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_interest_and_earnings` | interest and earnings | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_interest_and_penalties` | interest and penalties | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_interest_penalties` | interest penalties | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_library_grants_from_local_governments` | library grants from local governments | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_debt_proceeds` | miscellaneous debt proceeds | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_federal_aid` | miscellaneous federal aid | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_fees` | miscellaneous fees | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_grants_from_local_governments` | miscellaneous grants from local governments | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_intergovernmental_charges` | miscellaneous intergovernmental charges | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_non_property_taxes` | miscellaneous non property taxes | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_revenues` | miscellaneous revenues | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_state_aid` | miscellaneous state aid | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_tax_items` | miscellaneous tax items | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_miscellaneous_use_taxes` | miscellaneous use taxes | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_mortgage_tax` | mortgage tax | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_payments_in_lieu_of_taxes` | payments in lieu of taxes | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_public_safety_charges` | public safety charges | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_public_safety_fees` | public safety fees | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_real_property_taxes` | real property taxes | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_rental_of_property` | rental of property | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_sale_of_obligations` | sale of obligations | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_sale_of_property` | sale of property | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_sales_tax` | sales tax | C/Co | _TBD_ | _TBD_ |
| `rev_L2_sales_tax_distribution` | sales tax distribution | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_sanitation_charges` | sanitation charges | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_sanitation_fees` | sanitation fees | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_social_services_charges` | social services charges | Co | _TBD_ | _TBD_ |
| `rev_L2_social_services_fees` | social services fees | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_special_assessments` | special assessments | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_star_payments` | star payments | S | _TBD_ | _TBD_ |
| `rev_L2_state_aid_community_services` | state aid community services | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_state_aid_culture_and_recreation` | state aid culture and recreation | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_state_aid_economic_development` | state aid economic development | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_state_aid_education` | state aid education | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_state_aid_general_government` | state aid general government | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_state_aid_health` | state aid health | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_state_aid_public_safety` | state aid public safety | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_state_aid_sanitation` | state aid sanitation | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_state_aid_social_services` | state aid social services | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_state_aid_transportation` | state aid transportation | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_state_aid_utilities` | state aid utilities | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_transfers` | transfers | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_transportation_charges` | transportation charges | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_transportation_fees` | transportation fees | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_unrestricted_state_aid` | unrestricted state aid | C/Co/T/S | _TBD_ | _TBD_ |
| `rev_L2_utilities_gross_receipts_tax` | utilities gross receipts tax | C/Co/S | _TBD_ | _TBD_ |
| `rev_L2_utility_charges` | utility charges | C/Co/T | _TBD_ | _TBD_ |
| `rev_L2_utility_fees` | utility fees | C/Co/T | _TBD_ | _TBD_ |

## Derived / analysis variables

Resilience indicators, ratios, deflated/per-capita transforms, and shock indicators are
**not yet created**. Add them here as they are built (one row each), recording the exact
formula and the source variables they depend on.

| Variable | Definition / formula | Source variable(s) | Created in | Date added |
|---|---|---|---|---|
| _none yet_ | | | | |
