// Step 1: Find artists who belong to multiple styles
MATCH (a:Artist)-[:USES_STYLE]->(s1:Style)
MATCH (a)-[:USES_STYLE]->(s2:Style)
WHERE s1 <> s2  // Ensure the artist belongs to at least two different styles

// Step 2: Find if they collaborate with artists from styles they don’t directly belong to
MATCH (a)-[:FRIENDS_WITH|INFLUENCED|INFLUENCED_BY|TAUGHT|IS_PUPIL_OF]-(other:Artist)
MATCH (other)-[:USES_STYLE]->(other_style:Style)
WHERE NOT (a)-[:USES_STYLE]->(other_style)  // Ensures they connect styles beyond their own

WITH a, COUNT(DISTINCT other_style) AS connected_styles, COUNT(DISTINCT s1) AS style_count
RETURN a.name AS artist, a.birth_year, style_count, connected_styles
ORDER BY connected_styles DESC
LIMIT 10;
