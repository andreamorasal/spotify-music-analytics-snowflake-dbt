-- 01. Compare average audio features by target

SELECT
    TARGET,
    COUNT(*) AS TOTAL_SONGS,
    ROUND(AVG(DANCEABILITY), 3) AS AVG_DANCEABILITY,
    ROUND(AVG(ENERGY), 3) AS AVG_ENERGY,
    ROUND(AVG(VALENCE), 3) AS AVG_VALENCE,
    ROUND(AVG(TEMPO), 2) AS AVG_TEMPO
FROM SPOTIFY_ANALYTICS_DB.RAW.SPOTIFY_TRACKS
GROUP BY TARGET
ORDER BY TARGET;


-- 02. Categorise songs by danceability

SELECT
    CASE
        WHEN DANCEABILITY < 0.40 THEN 'Low'
        WHEN DANCEABILITY < 0.70 THEN 'Medium'
        ELSE 'High'
    END AS DANCEABILITY_CATEGORY,
    COUNT(*) AS TOTAL_SONGS
FROM SPOTIFY_ANALYTICS_DB.RAW.SPOTIFY_TRACKS
GROUP BY DANCEABILITY_CATEGORY
ORDER BY TOTAL_SONGS DESC;


-- 03. Check data quality in the staging view

SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DISTINCT SOURCE_ROW_ID) AS UNIQUE_IDS,
    COUNT_IF(SOURCE_ROW_ID IS NULL) AS NULL_IDS,
    COUNT_IF(SONG_TITLE IS NULL) AS NULL_TITLES,
    COUNT_IF(ARTIST IS NULL) AS NULL_ARTISTS
FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS;


-- 04. Validate audio feature ranges

SELECT
    MIN(DANCEABILITY) AS MIN_DANCEABILITY,
    MAX(DANCEABILITY) AS MAX_DANCEABILITY,
    MIN(ENERGY) AS MIN_ENERGY,
    MAX(ENERGY) AS MAX_ENERGY,
    MIN(VALENCE) AS MIN_VALENCE,
    MAX(VALENCE) AS MAX_VALENCE
FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS;


-- 05. Investigate song duration

SELECT
    MIN(DURATION_MS) AS MIN_DURATION_MS,
    MAX(DURATION_MS) AS MAX_DURATION_MS,
    ROUND(AVG(DURATION_MS) / 60000, 2) AS AVG_DURATION_MINUTES
FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS;


-- 06. Identify unusually short and long tracks

SELECT
    SONG_TITLE,
    ARTIST,
    ROUND(DURATION_MS / 1000, 2) AS DURATION_SECONDS,
    ROUND(DURATION_MS / 60000, 2) AS DURATION_MINUTES
FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS
WHERE DURATION_MS < 60000
   OR DURATION_MS > 600000
ORDER BY DURATION_MS;

-- Investigation note:
-- Identified 18 tracks shorter than 1 minute or longer than 10 minutes.
-- These records are retained because unusual duration does not necessarily
-- indicate incorrect data.


-- 07. Investigate TARGET distribution

SELECT
    TARGET,
    COUNT(*) AS TOTAL_RECORDS
FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS
GROUP BY TARGET
ORDER BY TARGET;

-- Investigation note:
-- TARGET contains two values: 0 (997 records) and 1 (1,020 records).
-- The distribution is approximately balanced.
-- The business meaning of TARGET is not yet verified.


-- 08. Identify repeated artist and song combinations

SELECT
    ARTIST,
    SONG_TITLE,
    COUNT(*) AS RECORD_COUNT,
    COUNT(DISTINCT TARGET) AS DISTINCT_TARGETS
FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS
GROUP BY ARTIST, SONG_TITLE
HAVING COUNT(*) > 1
ORDER BY RECORD_COUNT DESC, ARTIST;

-- Investigation note:
-- Found 33 repeated artist/song combinations.
-- 32 combinations appear twice and one appears three times.
-- Three combinations have different TARGET values:
-- Daft Punk - Get Lucky
-- Future - Mask Off
-- Kendrick Lamar - Swimming Pools (Drank) - Extended Version
-- All records are retained; no duplicates have been removed.


-- 09. Investigate repeated songs with different TARGET values

WITH conflicting_songs AS (
    SELECT
        ARTIST,
        SONG_TITLE
    FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS
    GROUP BY ARTIST, SONG_TITLE
    HAVING COUNT(DISTINCT TARGET) > 1
)

SELECT
    T.SOURCE_ROW_ID,
    T.ARTIST,
    T.SONG_TITLE,
    T.TARGET,
    T.DANCEABILITY,
    T.ENERGY,
    T.VALENCE,
    T.TEMPO
FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS T
INNER JOIN conflicting_songs C
    ON T.ARTIST = C.ARTIST
    AND T.SONG_TITLE = C.SONG_TITLE
ORDER BY T.ARTIST, T.SONG_TITLE, T.TARGET;

-- Investigation note:
-- Three artist/song combinations have conflicting TARGET values.
-- All six records have identical audio features within each combination.
-- This suggests TARGET is not determined solely by the audio features.
-- Records are retained pending verification of TARGET meaning and dataset provenance.


-- 10. Inspect source row ID range

SELECT
    MIN(SOURCE_ROW_ID) AS MIN_SOURCE_ROW_ID,
    MAX(SOURCE_ROW_ID) AS MAX_SOURCE_ROW_ID,
    COUNT(DISTINCT SOURCE_ROW_ID) AS UNIQUE_SOURCE_IDS,
    MAX(SOURCE_ROW_ID) - MIN(SOURCE_ROW_ID) + 1 AS EXPECTED_ID_COUNT
FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS;

-- Investigation note:
-- Source row IDs range from 0 to 2,016.
-- There are 2,017 unique IDs, matching the expected ID count.
-- No missing or duplicate source IDs were identified.


-- 11. Validate remaining audio feature ranges

SELECT
    MIN(ACOUSTICNESS) AS MIN_ACOUSTICNESS,
    MAX(ACOUSTICNESS) AS MAX_ACOUSTICNESS,
    MIN(INSTRUMENTALNESS) AS MIN_INSTRUMENTALNESS,
    MAX(INSTRUMENTALNESS) AS MAX_INSTRUMENTALNESS,
    MIN(LIVENESS) AS MIN_LIVENESS,
    MAX(LIVENESS) AS MAX_LIVENESS,
    MIN(SPEECHINESS) AS MIN_SPEECHINESS,
    MAX(SPEECHINESS) AS MAX_SPEECHINESS
FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.STG_SPOTIFY_TRACKS;

-- Investigation note:
-- Acousticness, instrumentalness, liveness and speechiness
-- all fall within the expected range of 0 to 1.
-- No out-of-range values were identified.


-- Query 12: Rank artists by average danceability

WITH artist_metrics AS (
    SELECT
        ARTIST,
        COUNT(*) AS TOTAL_TRACKS,
        ROUND(AVG(DANCEABILITY), 3) AS AVG_DANCEABILITY

    FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.FCT_TRACKS

    GROUP BY ARTIST

    HAVING COUNT(*) >= 5
)

SELECT
    ARTIST,
    TOTAL_TRACKS,
    AVG_DANCEABILITY,

    RANK() OVER (
        ORDER BY AVG_DANCEABILITY DESC
    ) AS DANCEABILITY_RANK

FROM artist_metrics

ORDER BY DANCEABILITY_RANK
LIMIT 10;



-- Query 13: Compare artist rankings by average energy and valence

WITH artist_metrics AS (
    SELECT
        ARTIST,
        COUNT(*) AS TOTAL_TRACKS,
        ROUND(AVG(DANCEABILITY), 3) AS AVG_DANCEABILITY,
        ROUND(AVG(ENERGY), 3) AS AVG_ENERGY,
        ROUND(AVG(VALENCE), 3) AS AVG_VALENCE

    FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.FCT_TRACKS

    GROUP BY ARTIST

    HAVING COUNT(*) >= 5
)

SELECT
    ARTIST,
    TOTAL_TRACKS,
    AVG_DANCEABILITY,
    AVG_ENERGY,
    AVG_VALENCE,

    RANK() OVER (
        ORDER BY AVG_ENERGY DESC
    ) AS ENERGY_RANK,

    RANK() OVER (
        ORDER BY AVG_VALENCE DESC
    ) AS VALENCE_RANK

FROM artist_metrics

ORDER BY ENERGY_RANK
LIMIT 15;



-- Query 14: Identify artists with the biggest energy and valence ranking gaps

WITH artist_metrics AS (
    SELECT
        ARTIST,
        COUNT(*) AS TOTAL_TRACKS,
        ROUND(AVG(ENERGY), 3) AS AVG_ENERGY,
        ROUND(AVG(VALENCE), 3) AS AVG_VALENCE

    FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.FCT_TRACKS

    GROUP BY ARTIST

    HAVING COUNT(*) >= 5
),

artist_rankings AS (
    SELECT
        ARTIST,
        TOTAL_TRACKS,
        AVG_ENERGY,
        AVG_VALENCE,

        RANK() OVER (
            ORDER BY AVG_ENERGY DESC
        ) AS ENERGY_RANK,

        RANK() OVER (
            ORDER BY AVG_VALENCE DESC
        ) AS VALENCE_RANK

    FROM artist_metrics
)

SELECT
    ARTIST,
    TOTAL_TRACKS,
    AVG_ENERGY,
    AVG_VALENCE,
    ENERGY_RANK,
    VALENCE_RANK,

    ENERGY_RANK - VALENCE_RANK AS RANK_DIFFERENCE,

    ABS(ENERGY_RANK - VALENCE_RANK) AS RANKING_GAP

FROM artist_rankings

ORDER BY RANKING_GAP DESC, ARTIST

LIMIT 15;



-- Query 15: Analyse the correlation between energy and danceability

SELECT
    COUNT(*) AS TOTAL_TRACKS,

    ROUND(
        CORR(ENERGY, DANCEABILITY),
        3
    ) AS ENERGY_DANCEABILITY_CORRELATION

FROM SPOTIFY_ANALYTICS_DB.ANALYTICS.FCT_TRACKS;

-- Investigation note:
-- The correlation between energy and danceability is 0.039,
-- indicating a very weak positive linear relationship.
-- In this dataset, energy and danceability are therefore
-- practically uncorrelated.
-- Higher energy does not necessarily mean higher danceability.