MATCH (a:Artist)
OPTIONAL MATCH (a)-[:STUDIED_AT]->(s:School)
OPTIONAL MATCH (a)-[:FRIENDS_WITH|INFLUENCED|INFLUENCED_BY|TAUGHT|IS_PUPIL_OF]-(collaborator)
WITH s, COUNT(DISTINCT a) AS total_artists, COUNT(DISTINCT collaborator) AS total_collaborations
RETURN 
  CASE WHEN s IS NOT NULL THEN 'Attended School' ELSE 'No School' END AS schooling_status,
  avg(total_collaborations * 1.0 / total_artists) AS avg_cluster_density;
