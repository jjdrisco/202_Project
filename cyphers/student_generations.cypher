MATCH path = (teacher:Artist)-[:TAUGHT*1..3]->(student:Artist)
RETURN teacher.name, COUNT(DISTINCT student) AS total_students
ORDER BY total_students DESC
LIMIT 10;
