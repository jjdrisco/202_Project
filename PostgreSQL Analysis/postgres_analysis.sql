SELECT
    m.movement_name,
    MIN(a.birth_year) AS earliest_birth,
    MAX(COALESCE(a.death_year, a.career_end_year, EXTRACT(YEAR FROM CURRENT_DATE))) AS latest_active_year,
    (MAX(COALESCE(a.death_year, a.career_end_year, EXTRACT(YEAR FROM CURRENT_DATE))) - MIN(a.birth_year)) AS active_duration
FROM artists a
JOIN artist_movements am ON a.artist_name = am.artist_name AND a.birth_year = am.birth_year
JOIN movements m ON am.movement_name = m.movement_name
GROUP BY m.movement_name
ORDER BY active_duration DESC;

SELECT nationality, COUNT(*) AS artist_count
FROM artists
WHERE birth_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 200
GROUP BY nationality
ORDER BY artist_count DESC;

SELECT
   o.occupation_name,
   COUNT(*) AS total_artists,
   COUNT(CASE WHEN a.birth_year < 1800 THEN 1 END) AS pre_1800,
   COUNT(CASE WHEN a.birth_year BETWEEN 1800 AND 1899 THEN 1 END) AS "19th_century",
   COUNT(CASE WHEN a.birth_year BETWEEN 1900 AND 1999 THEN 1 END) AS "20th_century",
   COUNT(CASE WHEN a.birth_year >= 2000 THEN 1 END) AS "21st_century"
FROM artist_occupations ao
JOIN artists a ON ao.artist_name = a.artist_name AND ao.birth_year = a.birth_year
JOIN occupations o ON ao.occupation_name = o.occupation_name
GROUP BY o.occupation_name
ORDER BY total_artists DESC;

SELECT
    s.school_name,
    COUNT(DISTINCT a.artist_name) AS total_artists,
    AVG(COALESCE(a.death_year, a.career_end_year, EXTRACT(YEAR FROM CURRENT_DATE)) - a.birth_year) AS avg_career_length,
    COUNT(DISTINCT st.style_name) AS style_diversity
FROM artist_schools asch
JOIN artists a ON asch.artist_name = a.artist_name AND asch.birth_year = a.birth_year
JOIN schools s ON asch.school_name = s.school_name
LEFT JOIN artist_styles ast ON a.artist_name = ast.artist_name AND a.birth_year = ast.birth_year
LEFT JOIN styles st ON ast.style_name = st.style_name
GROUP BY s.school_name
ORDER BY total_artists DESC, avg_career_length DESC, style_diversity DESC;

SELECT
    st.style_name,
    COUNT(DISTINCT a.artist_name) AS total_artists,
    MIN(a.birth_year) AS first_artist_birth,
    MAX(COALESCE(a.death_year, a.career_end_year, EXTRACT(YEAR FROM CURRENT_DATE))) AS last_active_year,
    (MAX(COALESCE(a.death_year, a.career_end_year, EXTRACT(YEAR FROM CURRENT_DATE))) - MIN(a.birth_year)) AS style_duration
FROM artist_styles ast
JOIN artists a ON ast.artist_name = a.artist_name AND ast.birth_year = a.birth_year
JOIN styles st ON ast.style_name = st.style_name
GROUP BY st.style_name
ORDER BY style_duration DESC, total_artists DESC;

SELECT
    COUNT(*) AS total_artists,
    COUNT(CASE WHEN (COALESCE(death_year, career_end_year, EXTRACT(YEAR FROM CURRENT_DATE)) - birth_year) / 2 + birth_year >= 50 THEN 1 END) AS late_bloomers,
    ROUND(100.0 * COUNT(CASE WHEN (COALESCE(death_year, career_end_year, EXTRACT(YEAR FROM CURRENT_DATE)) - birth_year) / 2 + birth_year >= 50 THEN 1 END) / COUNT(*), 2) AS late_bloomer_percentage
FROM artists;