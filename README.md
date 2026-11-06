# Spotify music analytics with Snowflake and dbt 🎧

An end-to-end data analytics project using Snowflake SQL and dbt to explore Spotify track characteristics, analyse artist performance and build analytics-ready data models.

## Project overview 🎸

This project analyses a dataset of 2,017 Spotify track records, exploring audio features such as danceability, energy, valence, acousticness, instrumentalness and tempo.

The goal is to develop practical SQL and analytics engineering skills, transform raw data into reliable analytical models using dbt, and prepare the results for an interactive Tableau dashboard.

## Dataset

The project uses a Spotify tracks dataset containing **2,017 records and 17 columns**.

The dataset includes:

- Track information: song title and artist
- Audio features: danceability, energy, valence, acousticness, instrumentalness and liveness
- Additional attributes: tempo, loudness, duration, musical key and time signature
- A binary `TARGET` field whose original business meaning is still being investigated

The original CSV dataset is included in the repository:

`data/spotify_data.csv`

## Tech stack

- **Snowflake:** Data storage, SQL analysis and transformations
- **dbt Fusion:** Data modelling, testing and documentation
- **SQL:** Data exploration, aggregations, CTEs, window functions and analytical queries
- **Git and GitHub:** Version control and project documentation
- **Tableau:** Planned data visualisation and dashboard development

## SQL analysis

The initial Snowflake SQL analysis includes 15 queries exploring:

- Track and artist distributions
- Audio feature statistics and comparisons
- Danceability and energy patterns
- Artist rankings by average audio features
- Relationships between energy and danceability
- Differences between artists' energy and valence rankings

The analysis uses aggregations, `GROUP BY`, `HAVING`, `CASE WHEN`, CTEs, window functions and correlation analysis.

## dbt data modelling

The dbt project currently includes three models:

| Model | Purpose | Materialisation |
|---|---|---|
| `stg_spotify_tracks` | Selects and prepares raw Spotify track records | View |
| `fct_tracks` | Creates a structured track-level fact table with derived duration in minutes | Table |
| `mart_artist_performance` | Aggregates track counts and average audio features by artist | Table |

## Data quality and testing

dbt tests validate the data and model outputs, including:

- Unique and non-null source record identifiers
- Required track and artist fields
- Valid ranges for audio features
- Non-null analytical metrics
- Valid artist-level track counts

**48 dbt tests have passed** across the current staging, fact and mart models.

## Project status

**In progress**

Completed:
- Snowflake environment and raw table setup
- Initial SQL analysis (15 queries)
- dbt staging model
- Track-level fact model
- Artist performance mart
- dbt documentation and data quality tests

Next:
- Further exploratory SQL analysis
- Additional analytical dbt models
- Expanded data quality testing
- Tableau dashboard development

## Notes

The meaning of the original dataset's `TARGET` field has not yet been verified. It will be investigated before drawing conclusions from it.