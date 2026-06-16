> ## Documentation Index
> Fetch the complete documentation index at: https://developers.openalex.org/llms.txt
> Use this file to discover all available pages before exploring further.

# Works Overview

> Schema reference for Works entities

Works are scholarly documents like journal articles, books, datasets, and theses. OpenAlex indexes hundreds of millions of works.

## Filter, sort, and group\_by fields

The API supports filtering, sorting, and grouping on works fields. See [Filtering](/guides/filtering), [Sorting](/guides/sort), and [Grouping](/guides/grouping) for syntax.

Fields marked **(deprecated)** are `.search` filters — use the [`search` parameter](/guides/searching) instead.

### Top-level

| Field                                              | Sort | Group\_by | Filter |
| -------------------------------------------------- | :--: | :-------: | :----: |
| `authors_count`                                    |   ✓  |     ✓     |    ✓   |
| `best_open_version`                                |   ✓  |     ✓     |    ✓   |
| `cited_by`                                         |      |           |    ✓   |
| `cited_by_count`                                   |   ✓  |     ✓     |    ✓   |
| `cites`                                            |      |           |    ✓   |
| `concepts_count`                                   |   ✓  |     ✓     |    ✓   |
| `corresponding_author_ids`                         |   ✓  |     ✓     |    ✓   |
| `corresponding_institution_ids`                    |   ✓  |     ✓     |    ✓   |
| `countries_distinct_count`                         |   ✓  |     ✓     |    ✓   |
| `created_date`                                     |   ✓  |           |    ✓   |
| `datasets`                                         |   ✓  |     ✓     |    ✓   |
| `display_name`                                     |   ✓  |           |    ✓   |
| `doi`                                              |   ✓  |           |    ✓   |
| `doi_starts_with`                                  |   ✓  |     ✓     |    ✓   |
| `from_created_date`                                |   ✓  |           |    ✓   |
| `from_publication_date`                            |   ✓  |           |    ✓   |
| `fulltext_origin`                                  |   ✓  |     ✓     |    ✓   |
| `fwci`                                             |   ✓  |           |    ✓   |
| `has_abstract`                                     |      |     ✓     |    ✓   |
| `has_doi`                                          |   ✓  |     ✓     |    ✓   |
| `has_embeddings`                                   |      |           |    ✓   |
| `has_fulltext`                                     |   ✓  |     ✓     |    ✓   |
| `has_oa_accepted_or_published_version`             |      |     ✓     |    ✓   |
| `has_oa_submitted_version`                         |      |     ✓     |    ✓   |
| `has_old_authors`                                  |      |     ✓     |    ✓   |
| `has_orcid`                                        |   ✓  |     ✓     |    ✓   |
| `has_pdf_url`                                      |   ✓  |     ✓     |    ✓   |
| `has_pmcid`                                        |   ✓  |     ✓     |    ✓   |
| `has_pmid`                                         |   ✓  |     ✓     |    ✓   |
| `has_raw_affiliation_strings`                      |      |     ✓     |    ✓   |
| `has_references`                                   |   ✓  |     ✓     |    ✓   |
| `indexed_in`                                       |   ✓  |     ✓     |    ✓   |
| `institutions_distinct_count`                      |   ✓  |     ✓     |    ✓   |
| `is_corresponding`                                 |   ✓  |     ✓     |    ✓   |
| `is_oa`                                            |      |     ✓     |    ✓   |
| `is_paratext` *(deprecated — use `type:paratext`)* |   ✓  |     ✓     |    ✓   |
| `is_retracted`                                     |   ✓  |     ✓     |    ✓   |
| `is_xpac`                                          |   ✓  |     ✓     |    ✓   |
| `journal`                                          |   ✓  |     ✓     |    ✓   |
| `language`                                         |   ✓  |     ✓     |    ✓   |
| `locations_count`                                  |   ✓  |     ✓     |    ✓   |
| `mag`                                              |   ✓  |           |    ✓   |
| `mag_only`                                         |      |     ✓     |    ✓   |
| `oa_status`                                        |      |     ✓     |    ✓   |
| `openalex`                                         |   ✓  |     ✓     |    ✓   |
| `openalex_id`                                      |      |     ✓     |    ✓   |
| `pmcid`                                            |   ✓  |           |    ✓   |
| `pmid`                                             |   ✓  |           |    ✓   |
| `publication_date`                                 |   ✓  |           |    ✓   |
| `publication_year`                                 |   ✓  |     ✓     |    ✓   |
| `raw_affiliation_strings`                          |   ✓  |     ✓     |    ✓   |
| `referenced_works`                                 |   ✓  |           |    ✓   |
| `referenced_works_count`                           |   ✓  |     ✓     |    ✓   |
| `related_to`                                       |      |           |    ✓   |
| `repository`                                       |   ✓  |     ✓     |    ✓   |
| `to_created_date`                                  |   ✓  |           |    ✓   |
| `to_publication_date`                              |   ✓  |           |    ✓   |
| `to_updated_date`                                  |   ✓  |           |    ✓   |
| `topics_count`                                     |      |           |    ✓   |
| `type`                                             |   ✓  |     ✓     |    ✓   |
| `updated_date`                                     |   ✓  |           |    ✓   |
| `version`                                          |   ✓  |     ✓     |    ✓   |

### Abstract

| Field                                      | Sort | Group\_by | Filter |
| ------------------------------------------ | :--: | :-------: | :----: |
| `abstract.search` **(deprecated)**         |      |           |    ✓   |
| `abstract.search.no_stem` **(deprecated)** |      |           |    ✓   |

### Apc List

| Field                 | Sort | Group\_by | Filter |
| --------------------- | :--: | :-------: | :----: |
| `apc_list.currency`   |   ✓  |     ✓     |    ✓   |
| `apc_list.provenance` |   ✓  |     ✓     |    ✓   |
| `apc_list.value`      |   ✓  |     ✓     |    ✓   |
| `apc_list.value_usd`  |   ✓  |     ✓     |    ✓   |

### Apc Paid

| Field                 | Sort | Group\_by | Filter |
| --------------------- | :--: | :-------: | :----: |
| `apc_paid.currency`   |   ✓  |     ✓     |    ✓   |
| `apc_paid.provenance` |   ✓  |     ✓     |    ✓   |
| `apc_paid.value`      |   ✓  |     ✓     |    ✓   |
| `apc_paid.value_usd`  |   ✓  |     ✓     |    ✓   |

### Author

| Field          | Sort | Group\_by | Filter |
| -------------- | :--: | :-------: | :----: |
| `author.id`    |      |     ✓     |    ✓   |
| `author.orcid` |      |     ✓     |    ✓   |

### Authorships

| Field                                      | Sort | Group\_by | Filter |
| ------------------------------------------ | :--: | :-------: | :----: |
| `authorships.affiliations.institution_ids` |   ✓  |     ✓     |    ✓   |
| `authorships.author.id`                    |   ✓  |     ✓     |    ✓   |
| `authorships.author.orcid`                 |   ✓  |     ✓     |    ✓   |
| `authorships.countries`                    |   ✓  |     ✓     |    ✓   |
| `authorships.institutions.continent`       |   ✓  |     ✓     |    ✓   |
| `authorships.institutions.country_code`    |   ✓  |     ✓     |    ✓   |
| `authorships.institutions.id`              |   ✓  |     ✓     |    ✓   |
| `authorships.institutions.is_global_south` |   ✓  |     ✓     |    ✓   |
| `authorships.institutions.lineage`         |   ✓  |     ✓     |    ✓   |
| `authorships.institutions.ror`             |   ✓  |     ✓     |    ✓   |
| `authorships.institutions.type`            |   ✓  |     ✓     |    ✓   |
| `authorships.is_corresponding`             |   ✓  |     ✓     |    ✓   |

### Awards

| Field                        | Sort | Group\_by | Filter |
| ---------------------------- | :--: | :-------: | :----: |
| `awards.doi`                 |   ✓  |     ✓     |    ✓   |
| `awards.funder_award_id`     |   ✓  |     ✓     |    ✓   |
| `awards.funder_display_name` |   ✓  |     ✓     |    ✓   |
| `awards.funder_id`           |   ✓  |     ✓     |    ✓   |
| `awards.id`                  |   ✓  |     ✓     |    ✓   |

### Best Oa Location

| Field                                               | Sort | Group\_by | Filter |
| --------------------------------------------------- | :--: | :-------: | :----: |
| `best_oa_location.is_accepted`                      |   ✓  |     ✓     |    ✓   |
| `best_oa_location.is_oa`                            |   ✓  |     ✓     |    ✓   |
| `best_oa_location.is_published`                     |   ✓  |     ✓     |    ✓   |
| `best_oa_location.landing_page_url`                 |   ✓  |     ✓     |    ✓   |
| `best_oa_location.license`                          |   ✓  |     ✓     |    ✓   |
| `best_oa_location.license_id`                       |   ✓  |     ✓     |    ✓   |
| `best_oa_location.raw_type`                         |      |           |    ✓   |
| `best_oa_location.source.host_organization`         |   ✓  |     ✓     |    ✓   |
| `best_oa_location.source.host_organization_lineage` |   ✓  |     ✓     |    ✓   |
| `best_oa_location.source.id`                        |   ✓  |     ✓     |    ✓   |
| `best_oa_location.source.is_in_doaj`                |   ✓  |     ✓     |    ✓   |
| `best_oa_location.source.is_oa`                     |   ✓  |     ✓     |    ✓   |
| `best_oa_location.source.issn`                      |   ✓  |     ✓     |    ✓   |
| `best_oa_location.source.type`                      |   ✓  |     ✓     |    ✓   |
| `best_oa_location.version`                          |   ✓  |     ✓     |    ✓   |

### Biblio

| Field               | Sort | Group\_by | Filter |
| ------------------- | :--: | :-------: | :----: |
| `biblio.first_page` |   ✓  |           |    ✓   |
| `biblio.issue`      |   ✓  |     ✓     |    ✓   |
| `biblio.last_page`  |   ✓  |           |    ✓   |
| `biblio.volume`     |   ✓  |     ✓     |    ✓   |

### Citation Normalized Percentile

| Field                                                 | Sort | Group\_by | Filter |
| ----------------------------------------------------- | :--: | :-------: | :----: |
| `citation_normalized_percentile.is_in_top_10_percent` |   ✓  |     ✓     |    ✓   |
| `citation_normalized_percentile.is_in_top_1_percent`  |   ✓  |     ✓     |    ✓   |
| `citation_normalized_percentile.value`                |   ✓  |           |    ✓   |

### Cited By Percentile Year

| Field                          | Sort | Group\_by | Filter |
| ------------------------------ | :--: | :-------: | :----: |
| `cited_by_percentile_year.max` |   ✓  |     ✓     |    ✓   |
| `cited_by_percentile_year.min` |   ✓  |     ✓     |    ✓   |

### Concept

| Field        | Sort | Group\_by | Filter |
| ------------ | :--: | :-------: | :----: |
| `concept.id` |      |     ✓     |    ✓   |

### Concepts

| Field               | Sort | Group\_by | Filter |
| ------------------- | :--: | :-------: | :----: |
| `concepts.id`       |   ✓  |     ✓     |    ✓   |
| `concepts.wikidata` |   ✓  |     ✓     |    ✓   |

### Default

| Field                             | Sort | Group\_by | Filter |
| --------------------------------- | :--: | :-------: | :----: |
| `default.search` **(deprecated)** |      |           |    ✓   |

### Display Name

| Field                                          | Sort | Group\_by | Filter |
| ---------------------------------------------- | :--: | :-------: | :----: |
| `display_name.search` **(deprecated)**         |      |           |    ✓   |
| `display_name.search.no_stem` **(deprecated)** |      |           |    ✓   |

### Fulltext

| Field                              | Sort | Group\_by | Filter |
| ---------------------------------- | :--: | :-------: | :----: |
| `fulltext.search` **(deprecated)** |      |           |    ✓   |

### Funders

| Field        | Sort | Group\_by | Filter |
| ------------ | :--: | :-------: | :----: |
| `funders.id` |   ✓  |     ✓     |    ✓   |

### Has Content

| Field                    | Sort | Group\_by | Filter |
| ------------------------ | :--: | :-------: | :----: |
| `has_content.grobid_xml` |   ✓  |     ✓     |    ✓   |
| `has_content.pdf`        |   ✓  |     ✓     |    ✓   |

### Ids

| Field          | Sort | Group\_by | Filter |
| -------------- | :--: | :-------: | :----: |
| `ids.mag`      |   ✓  |           |    ✓   |
| `ids.openalex` |   ✓  |     ✓     |    ✓   |
| `ids.pmcid`    |   ✓  |           |    ✓   |
| `ids.pmid`     |   ✓  |           |    ✓   |

### Institution

| Field            | Sort | Group\_by | Filter |
| ---------------- | :--: | :-------: | :----: |
| `institution.id` |      |     ✓     |    ✓   |

### Institution Assertions

| Field                                 | Sort | Group\_by | Filter |
| ------------------------------------- | :--: | :-------: | :----: |
| `institution_assertions.country_code` |   ✓  |     ✓     |    ✓   |
| `institution_assertions.id`           |   ✓  |     ✓     |    ✓   |
| `institution_assertions.lineage`      |   ✓  |     ✓     |    ✓   |
| `institution_assertions.ror`          |   ✓  |     ✓     |    ✓   |
| `institution_assertions.type`         |   ✓  |     ✓     |    ✓   |

### Institutions

| Field                          | Sort | Group\_by | Filter |
| ------------------------------ | :--: | :-------: | :----: |
| `institutions.continent`       |      |     ✓     |    ✓   |
| `institutions.country_code`    |   ✓  |     ✓     |    ✓   |
| `institutions.id`              |   ✓  |     ✓     |    ✓   |
| `institutions.is_global_south` |   ✓  |     ✓     |    ✓   |
| `institutions.ror`             |   ✓  |     ✓     |    ✓   |
| `institutions.type`            |   ✓  |     ✓     |    ✓   |

### Keyword

| Field                             | Sort | Group\_by | Filter |
| --------------------------------- | :--: | :-------: | :----: |
| `keyword.search` **(deprecated)** |   ✓  |           |    ✓   |

### Keywords

| Field         | Sort | Group\_by | Filter |
| ------------- | :--: | :-------: | :----: |
| `keywords.id` |   ✓  |     ✓     |    ✓   |

### Locations

| Field                                        | Sort | Group\_by | Filter |
| -------------------------------------------- | :--: | :-------: | :----: |
| `locations.is_accepted`                      |   ✓  |     ✓     |    ✓   |
| `locations.is_oa`                            |   ✓  |     ✓     |    ✓   |
| `locations.is_published`                     |   ✓  |     ✓     |    ✓   |
| `locations.landing_page_url`                 |   ✓  |     ✓     |    ✓   |
| `locations.license`                          |   ✓  |     ✓     |    ✓   |
| `locations.license_id`                       |   ✓  |     ✓     |    ✓   |
| `locations.raw_type`                         |      |           |    ✓   |
| `locations.source.has_issn`                  |   ✓  |     ✓     |    ✓   |
| `locations.source.host_institution_lineage`  |   ✓  |     ✓     |    ✓   |
| `locations.source.host_organization`         |   ✓  |     ✓     |    ✓   |
| `locations.source.host_organization_lineage` |   ✓  |     ✓     |    ✓   |
| `locations.source.id`                        |   ✓  |     ✓     |    ✓   |
| `locations.source.is_core`                   |   ✓  |     ✓     |    ✓   |
| `locations.source.is_in_doaj`                |   ✓  |     ✓     |    ✓   |
| `locations.source.is_oa`                     |   ✓  |     ✓     |    ✓   |
| `locations.source.issn`                      |   ✓  |     ✓     |    ✓   |
| `locations.source.publisher_lineage`         |   ✓  |     ✓     |    ✓   |
| `locations.source.type`                      |   ✓  |     ✓     |    ✓   |
| `locations.version`                          |   ✓  |     ✓     |    ✓   |

### Open Access

| Field                                     | Sort | Group\_by | Filter |
| ----------------------------------------- | :--: | :-------: | :----: |
| `open_access.any_repository_has_fulltext` |   ✓  |     ✓     |    ✓   |
| `open_access.is_oa`                       |   ✓  |     ✓     |    ✓   |
| `open_access.oa_status`                   |   ✓  |     ✓     |    ✓   |

### Primary Location

| Field                                               | Sort | Group\_by | Filter |
| --------------------------------------------------- | :--: | :-------: | :----: |
| `primary_location.is_accepted`                      |   ✓  |     ✓     |    ✓   |
| `primary_location.is_oa`                            |   ✓  |     ✓     |    ✓   |
| `primary_location.is_published`                     |   ✓  |     ✓     |    ✓   |
| `primary_location.landing_page_url`                 |   ✓  |     ✓     |    ✓   |
| `primary_location.license`                          |   ✓  |     ✓     |    ✓   |
| `primary_location.license_id`                       |   ✓  |     ✓     |    ✓   |
| `primary_location.raw_type`                         |      |           |    ✓   |
| `primary_location.source.has_issn`                  |   ✓  |     ✓     |    ✓   |
| `primary_location.source.host_institution_lineage`  |   ✓  |     ✓     |    ✓   |
| `primary_location.source.host_organization`         |   ✓  |     ✓     |    ✓   |
| `primary_location.source.host_organization_lineage` |   ✓  |     ✓     |    ✓   |
| `primary_location.source.id`                        |   ✓  |     ✓     |    ✓   |
| `primary_location.source.is_core`                   |   ✓  |     ✓     |    ✓   |
| `primary_location.source.is_in_doaj`                |   ✓  |     ✓     |    ✓   |
| `primary_location.source.is_oa`                     |   ✓  |     ✓     |    ✓   |
| `primary_location.source.issn`                      |   ✓  |     ✓     |    ✓   |
| `primary_location.source.publisher_lineage`         |   ✓  |     ✓     |    ✓   |
| `primary_location.source.type`                      |   ✓  |     ✓     |    ✓   |
| `primary_location.version`                          |   ✓  |     ✓     |    ✓   |

### Primary Topic

| Field                       | Sort | Group\_by | Filter |
| --------------------------- | :--: | :-------: | :----: |
| `primary_topic.domain.id`   |   ✓  |     ✓     |    ✓   |
| `primary_topic.field.id`    |   ✓  |     ✓     |    ✓   |
| `primary_topic.id`          |   ✓  |     ✓     |    ✓   |
| `primary_topic.subfield.id` |   ✓  |     ✓     |    ✓   |

### Raw Affiliation Strings

| Field                                             | Sort | Group\_by | Filter |
| ------------------------------------------------- | :--: | :-------: | :----: |
| `raw_affiliation_strings.search` **(deprecated)** |      |           |    ✓   |

### Raw Author Name

| Field                                     | Sort | Group\_by | Filter |
| ----------------------------------------- | :--: | :-------: | :----: |
| `raw_author_name.search` **(deprecated)** |      |           |    ✓   |

### Semantic

| Field                              | Sort | Group\_by | Filter |
| ---------------------------------- | :--: | :-------: | :----: |
| `semantic.search` **(deprecated)** |      |           |    ✓   |

### Sustainable Development Goals

| Field                                 | Sort | Group\_by | Filter |
| ------------------------------------- | :--: | :-------: | :----: |
| `sustainable_development_goals.id`    |   ✓  |     ✓     |    ✓   |
| `sustainable_development_goals.score` |   ✓  |           |    ✓   |

### Title

| Field                                   | Sort | Group\_by | Filter |
| --------------------------------------- | :--: | :-------: | :----: |
| `title.search` **(deprecated)**         |      |           |    ✓   |
| `title.search.no_stem` **(deprecated)** |      |           |    ✓   |

### Title And Abstract

| Field                                                | Sort | Group\_by | Filter |
| ---------------------------------------------------- | :--: | :-------: | :----: |
| `title_and_abstract.search` **(deprecated)**         |      |           |    ✓   |
| `title_and_abstract.search.no_stem` **(deprecated)** |      |           |    ✓   |

### Topics

| Field                | Sort | Group\_by | Filter |
| -------------------- | :--: | :-------: | :----: |
| `topics.domain.id`   |   ✓  |     ✓     |    ✓   |
| `topics.field.id`    |   ✓  |     ✓     |    ✓   |
| `topics.id`          |   ✓  |     ✓     |    ✓   |
| `topics.subfield.id` |   ✓  |     ✓     |    ✓   |
