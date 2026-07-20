WITH seasonal_trends AS (
    SELECT
        d.year,
        d.month,
        COUNT(*) AS total_sightings
    FROM dbo.fact_observations f
    JOIN dbo.dim_date d ON f.Date_Key = d.Date_Key
    GROUP BY d.year, d.month
)
SELECT
    year,
    month,
    total_sightings,
    LAG(total_sightings) OVER (PARTITION BY month ORDER BY year) AS prev_year,
    total_sightings - LAG(total_sightings) OVER (PARTITION BY month ORDER BY year) AS yoy_change
FROM seasonal_trends;

WITH plot_counts AS (
    SELECT
        p.plot_name,
        d.Date_Key,
        COUNT(*) AS daily_count
    FROM dbo.fact_observations f
    JOIN dbo.dim_plot p ON f.Plot_Name = p.Plot_Name
    JOIN dbo.dim_date d ON f.Date_Key = d.Date_Key
    GROUP BY p.plot_name, d.Date_Key
)
SELECT
    plot_name,
    Date_Key,
    daily_count,
    SUM(daily_count) OVER (
        PARTITION BY plot_name
        ORDER BY Date_Key
    ) AS running_total
FROM plot_counts;


WITH species_diversity AS (
    SELECT
        p.Location_Type,
        COUNT(DISTINCT s.Scientific_Name) AS unique_species
    FROM dbo.fact_observations f
    JOIN dbo.dim_species s ON f.AOU_Code = s.AOU_Code
    JOIN dbo.dim_plot p ON f.Plot_Name = p.Plot_Name
    GROUP BY p.Location_Type
)
SELECT * FROM species_diversity;


WITH sex_counts AS (
    SELECT
        s.Scientific_Name,
        SUM(CASE WHEN f.Sex = 'Male' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN f.Sex = 'Female' THEN 1 ELSE 0 END) AS female_count
    FROM dbo.fact_observations f
    JOIN dbo.dim_species s ON f.AOU_Code = s.AOU_Code
    WHERE f.Sex IN ('Male', 'Female')
    GROUP BY s.Scientific_Name
)
SELECT *,
    CASE 
        WHEN female_count = 0 THEN NULL
        ELSE CAST(male_count AS FLOAT) / female_count
    END AS ratio
FROM sex_counts;

SELECT
    f.Distance,
    f.Season,
    COUNT(*) AS observations
FROM dbo.fact_observations f
GROUP BY f.Distance, f.Season
ORDER BY observations DESC;


SELECT
    f.Habitat_Source,
    COUNT(DISTINCT s.Scientific_Name) AS species_count
FROM dbo.fact_observations f
JOIN dbo.dim_species s ON f.AOU_Code = s.AOU_Code
GROUP BY f.Habitat_Source;

SELECT
    f.Habitat_Source,
    COUNT(DISTINCT s.Scientific_Name) AS species_count
FROM dbo.fact_observations f
JOIN dbo.dim_species s ON f.AOU_Code = s.AOU_Code
GROUP BY f.Habitat_Source;


WITH method_counts AS (
    SELECT
        p.Location_Type,
        f.ID_Method,
        COUNT(*) AS cnt
    FROM dbo.fact_observations f
    JOIN dbo.dim_plot p ON f.Plot_Name = p.Plot_Name
    GROUP BY p.Location_Type, f.ID_Method
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY Location_Type ORDER BY cnt DESC) AS rnk
    FROM method_counts
)
SELECT *
FROM ranked
WHERE rnk = 1;

---Flyover %--
SELECT
    COUNT(CASE WHEN f.Flyover_Observed = 1 THEN 1 END) * 100.0 / COUNT(*) AS flyover_pct
FROM dbo.fact_observations f;



WITH observer_counts AS (
    SELECT
        o.Observer_Name,
        COUNT(*) AS total_obs
    FROM dbo.fact_observations f
    JOIN dbo.dim_observer o 
        ON f.Observer_ID = o.Observer_ID
    GROUP BY o.Observer_Name
),
observer_with_avg AS (
    SELECT *,
        AVG(total_obs) OVER () AS avg_obs
    FROM observer_counts
)
SELECT *
FROM observer_with_avg
WHERE total_obs > avg_obs;


WITH visit_species AS (
    SELECT
        f.Visit,
        COUNT(DISTINCT s.Scientific_Name) AS species_count
    FROM dbo.fact_observations f
    JOIN dbo.dim_species s ON f.AOU_Code = s.AOU_Code
    GROUP BY f.Visit
)
SELECT *,
    LAG(species_count) OVER (ORDER BY Visit) AS prev_visit
FROM visit_species;


WITH watchlist AS (
    SELECT
        s.Scientific_Name,
        s.PIF_Watchlist_Status,
        COUNT(*) AS sightings
    FROM dbo.fact_observations f
    JOIN dbo.dim_species s ON f.AOU_Code = s.AOU_Code
    WHERE s.PIF_Watchlist_Status = 1
    GROUP BY s.Scientific_Name, s.PIF_Watchlist_Status
)
SELECT *,
    RANK() OVER (ORDER BY sightings DESC) AS rnk
FROM watchlist;

SELECT
    d.Year,
    d.Month,
    COUNT(*) AS total_sightings,
    COUNT(DISTINCT s.Scientific_Name) AS species_count
FROM dbo.fact_observations f
JOIN dbo.dim_date d ON f.Date_Key = d.Date_Key
JOIN dbo.dim_species s ON f.AOU_Code = s.AOU_Code
GROUP BY d.Year, d.Month
ORDER BY d.Year, d.Month;

