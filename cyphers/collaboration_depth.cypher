MATCH path = (a1:Artist)-[:STUDIED_AT]->(s1:School)<-[:STUDIED_AT]-(a2:Artist)-[:FRIENDS_WITH|INFLUENCED|INFLUENCED_BY|TAUGHT|IS_PUPIL_OF*1..3]-(a3:Artist)
RETURN s1.name AS school, avg(length(path)) AS avg_collaboration_depth, COUNT(DISTINCT a3) AS collaboration_count
ORDER BY avg_collaboration_depth DESC;
