-- Spatial Outliers
SELECT *
FROM winter-legend-mg.cyclist.cycle_trip
WHERE start_lat NOT BETWEEN 41.6 AND 42.1
OR start_lng NOT BETWEEN -88 AND -87;

-- Checking for Anomalies in start_station_name
SELECT start_station_name,
LENGTH(start_station_name) AS original_length,
LENGTH(TRIM(start_station_name)) AS new_length,
start_station_name != TRIM(start_station_name) AS has_whitespace,
start_station_name != INITCAP(LOWER(TRIM(start_station_name))) AS has_casing_issue
FROM winter-legend-mg.cyclist.cycle_trip
GROUP BY start_station_name
ORDER BY start_station_name;

-- Check for Station Names with Multiple Coordinate Variants
SELECT start_station_name,
COUNT(DISTINCT ROUND(start_lat, 3) || ',' || ROUND(start_lng, 3)) AS coordinate_variants
FROM `winter-legend-mg.cyclist.cycle_trip`
GROUP BY start_station_name
HAVING coordinate_variants > 1;

-- Check for Station Names Missing Station IDs
SELECT start_station_name, start_station_ID
FROM `winter-legend-mg.cyclist.cycle_trip`
WHERE start_station_name IS NOT NULL
AND (start_station_id IS NULL OR TRIM(start_station_id) = '')
ORDER BY start_station_name;

SELECT end_station_name, end_station_ID
FROM `winter-legend-mg.cyclist.cycle_trip`
WHERE end_station_name IS NOT NULL
AND (end_station_id IS NULL OR TRIM(end_station_id) = '')
ORDER BY end_station_name;

-- Validating Timestamp Consistency
SELECT *
FROM winter-legend-mg.cyclist.cycle_trip
WHERE ended_at < started_at;

-- Flag Negative Duration
SELECT ride_id, started_at, ended_at,
TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS ride_duration_minutes
FROM winter-legend-mg.cyclist.cycle_trip
WHERE TIMESTAMP_DIFF(ended_at, started_at, MINUTE) < 0;

-- Validating Categorical Fields
SELECT DISTINCT rideable_type
FROM winter-legend-mg.cyclist.cycle_trip;

SELECT DISTINCT member_casual
FROM winter-legend-mg.cyclist.cycle_trip;

-- Ride Volume and User Distribution
SELECT COUNT(*) AS total_ride_count,
COUNTIF(member_casual = 'member') AS member_rides,
COUNTIF(member_casual = 'casual') AS casual_rides
FROM winter-legend-mg.cyclist.cycle_trip;


-- Process Phase

-- Drop and recreate the cleaned table
DROP TABLE IF EXISTS winter-legend-mg.cyclist.cleaned_cycle_trip;
CREATE TABLE winter-legend-mg.cyclist.cleaned_cycle_trip AS
SELECT
  ride_id,
  rideable_type,
  started_at,
  ended_at,
  start_station_name,
  start_station_id,
  start_lat,
  start_lng,
  member_casual
FROM
  winter-legend-mg.cyclist.cycle_trip
WHERE
  start_station_name IS NOT NULL AND
  start_station_id IS NOT NULL AND
  start_lat IS NOT NULL AND
  start_lng IS NOT NULL AND
  started_at IS NOT NULL AND
  ended_at IS NOT NULL AND
  TIMESTAMP_DIFF(ended_at, started_at, MINUTE) BETWEEN 1 AND 1440;

-- Extracting month, day, and time
SELECT *,
  DATE(started_at) AS start_date,
  FORMAT_TIMESTAMP('%B', started_at) AS start_month,
  FORMAT_TIMESTAMP('%A', started_at) AS start_day_of_week,
  TIME(started_at) AS start_time,
  DATE(ended_at) AS end_date,
  FORMAT_TIMESTAMP('%B', ended_at) AS end_month,
  FORMAT_TIMESTAMP('%A', ended_at) AS end_day_of_week,
  TIME(ended_at) AS end_time
FROM
  winter-legend-mg.cyclist.cleaned_cycle_trip;

-- Final version of cleaned table
SELECT
  ride_id,
  rideable_type,
  start_date,
  start_month,
  start_day_of_week,
  start_time,
  start_station_name,
  start_station_id,
  start_lat,
  start_lng,
  member_casual
FROM
  winter-legend-mg.cyclist.cleaned_cycle_trip;


-- Analyze Phase

-- Bike Type Usage by Rider Category
SELECT member_casual, rideable_type,
COUNT(*) AS total_rides
FROM winter-legend-mg.cyclist.final_cycle_trip
GROUP BY member_casual, rideable_type
ORDER BY member_casual, total_rides DESC;

-- Monthly Trip Distribution
SELECT start_month, member_casual,
COUNT(*) AS total_rides
FROM winter-legend-mg.cyclist.final_cycle_trip
GROUP BY start_month, member_casual
ORDER BY start_month, total_rides DESC;

-- Weekly Usage Trends
SELECT start_day_of_week, member_casual,
COUNT(*) AS total_rides
FROM winter-legend-mg.cyclist.final_cycle_trip
GROUP BY start_day_of_week, member_casual
ORDER BY start_day_of_week, total_rides;

-- Hourly Ride Distribution
SELECT EXTRACT(HOUR FROM start_time) AS hour_of_day,
member_casual, COUNT(*) AS total_rides
FROM winter-legend-mg.cyclist.final_cycle_trip
GROUP BY hour_of_day, member_casual
ORDER BY hour_of_day, total_rides;

-- Average Ride Duration per Month
SELECT start_month, member_casual,
ROUND(AVG(ride_lenght_minutes), 2) AS avg_ride_length_per_month
FROM winter-legend-mg.cyclist.final_cycle_trip
GROUP BY start_month, member_casual
ORDER BY member_casual, start_month;

-- Most Popular Start Stations
SELECT start_station_name, member_casual,
COUNT(*) AS ride_count
FROM winter-legend-mg.cyclist.final_cycle_trip
WHERE start_station_name IS NOT NULL
GROUP BY start_station_name, member_casual
ORDER BY ride_count DESC;

