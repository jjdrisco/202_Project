// Artists (Primary Key: artist_name + birth_year)
CREATE CONSTRAINT FOR (a:Artist) REQUIRE (a.name, a.birth_year) IS UNIQUE;

// Places (Primary Key: place_name)
CREATE CONSTRAINT FOR (p:Place) REQUIRE p.name IS UNIQUE;

// Occupations (Primary Key: occupation_name)
CREATE CONSTRAINT FOR (o:Occupation) REQUIRE o.name IS UNIQUE;

// Schools (Primary Key: school_name)
CREATE CONSTRAINT FOR (s:School) REQUIRE s.name IS UNIQUE;

// Artworks (Primary Key: title + artwork_date)
CREATE CONSTRAINT FOR (art:Artwork) REQUIRE (art.title, art.artwork_date) IS UNIQUE;

// Movements (Primary Key: movement_name)
CREATE CONSTRAINT FOR (m:Movement) REQUIRE m.name IS UNIQUE;

// Styles (Primary Key: style_name)
CREATE CONSTRAINT FOR (st:Style) REQUIRE st.name IS UNIQUE;


// Create Artists
LOAD CSV WITH HEADERS FROM 'file:///artists.csv' AS row
MERGE (a:Artist {name: row.artist_name, birth_year: COALESCE(toInteger(row.birth_year), -999999)})
SET a.nationality = row.nationality,
    a.citizenship = row.citizenship,
    a.gender = row.gender,
    a.death_year = CASE 
        WHEN row.death_year IS NOT NULL AND row.death_year <> "" THEN toInteger(row.death_year)
        ELSE NULL
    END,
    a.career_start_year = CASE 
        WHEN row.career_start_year IS NOT NULL AND row.career_start_year <> "" THEN toInteger(row.career_start_year)
        ELSE NULL
    END,
    a.career_end_year = CASE 
        WHEN row.career_end_year IS NOT NULL AND row.career_end_year <> "" THEN toInteger(row.career_end_year)
        ELSE NULL
    END;

// Create Places
LOAD CSV WITH HEADERS FROM 'file:///places.csv' AS row
MERGE (p:Place {name: row.place_name});

// Create Occupations
LOAD CSV WITH HEADERS FROM 'file:///occupations.csv' AS row
MERGE (o:Occupation {name: row.occupation_name});

// Create Schools
LOAD CSV WITH HEADERS FROM 'file:///schools.csv' AS row
MERGE (s:School {name: row.school_name});

LOAD CSV WITH HEADERS FROM 'file:///artworks.csv' AS row
WITH row WHERE row.title IS NOT NULL AND row.title <> ""
MERGE (a:Artwork {title: row.title, artwork_date: toInteger(row.artwork_date)})
SET a.medium = row.medium,
    a.department = row.department,
    a.date_acquired = row.date_acquired,
    a.art_classification = row.art_classification,
    a.credit_line = row.credit_line;



// Create Movements
LOAD CSV WITH HEADERS FROM 'file:///movements.csv' AS row
MERGE (m:Movement {name: row.movement_name});

// Create Styles
LOAD CSV WITH HEADERS FROM 'file:///styles.csv' AS row
MERGE (st:Style {name: row.style_name});


// Artist Birth Places
LOAD CSV WITH HEADERS FROM 'file:///artist_birth_places.csv' AS row
MATCH (a:Artist {name: row.artist_name, birth_year: toInteger(row.birth_year)})
MATCH (p:Place {name: row.place_name})
MERGE (a)-[:BORN_IN]->(p);

// Artist Death Places
LOAD CSV WITH HEADERS FROM 'file:///artist_death_places.csv' AS row
MATCH (a:Artist {name: row.artist_name, birth_year: toInteger(row.birth_year)})
MATCH (p:Place {name: row.place_name})
MERGE (a)-[:DIED_IN]->(p);

// Artist Occupations
LOAD CSV WITH HEADERS FROM 'file:///artist_occupations.csv' AS row
MATCH (a:Artist {name: row.artist_name, birth_year: toInteger(row.birth_year)})
MATCH (o:Occupation {name: row.occupation_name})
MERGE (a)-[:HAS_OCCUPATION]->(o);

// Artist Schools
LOAD CSV WITH HEADERS FROM 'file:///artist_schools.csv' AS row
MATCH (a:Artist {name: row.artist_name, birth_year: toInteger(row.birth_year)})
MATCH (s:School {name: row.school_name})
MERGE (a)-[:STUDIED_AT]->(s)
SET a.time_period = row.time_period;

// Artworks & Artists Relationship
LOAD CSV WITH HEADERS FROM 'file:///artworks_artists.csv' AS row
MATCH (a:Artist {name: row.artist_name, birth_year: toInteger(row.birth_year)})
MATCH (art:Artwork {title: row.title, artwork_date: toInteger(row.artwork_date)})
MERGE (a)-[:CREATED]->(art);

// Artist Movements
LOAD CSV WITH HEADERS FROM 'file:///artist_movements.csv' AS row
MATCH (a:Artist {name: row.artist_name, birth_year: toInteger(row.birth_year)})
MATCH (m:Movement {name: row.movement_name})
MERGE (a)-[:BELONGS_TO_MOVEMENT]->(m);

// Artist Styles
LOAD CSV WITH HEADERS FROM 'file:///artist_styles.csv' AS row
MATCH (a:Artist {name: row.artist_name, birth_year: toInteger(row.birth_year)})
MATCH (st:Style {name: row.style_name})
MERGE (a)-[:USES_STYLE]->(st)
SET a.style_count = toInteger(row.style_count),
    a.style_years = row.style_years;

// Artist Pupil Relationships
LOAD CSV WITH HEADERS FROM 'file:///artist_relationships.csv' AS row
WITH row WHERE row.relationship_type = 'Pupil'
MATCH (a1:Artist {name: row.artist1_name, birth_year: toInteger(row.birth_year1)})
MATCH (a2:Artist {name: row.artist2_name})
MERGE (a1)-[:IS_PUPIL_OF]->(a2);

// Artist Teacher Relationships
LOAD CSV WITH HEADERS FROM 'file:///artist_relationships.csv' AS row
WITH row WHERE row.relationship_type = 'Teacher'
MATCH (a1:Artist {name: row.artist1_name, birth_year: toInteger(row.birth_year1)})
MATCH (a2:Artist {name: row.artist2_name})
MERGE (a1)-[:TAUGHT]->(a2);

// Artist Friend Relationships
LOAD CSV WITH HEADERS FROM 'file:///artist_relationships.csv' AS row
WITH row WHERE row.relationship_type = 'Friend'
MATCH (a1:Artist {name: row.artist1_name, birth_year: toInteger(row.birth_year1)})
MATCH (a2:Artist {name: row.artist2_name})
MERGE (a1)-[:FRIENDS_WITH]->(a2);

// Artist Influenced By Relationships
LOAD CSV WITH HEADERS FROM 'file:///artist_relationships.csv' AS row
WITH row WHERE row.relationship_type = 'Influenced By'
MATCH (a1:Artist {name: row.artist1_name, birth_year: toInteger(row.birth_year1)})
MATCH (a2:Artist {name: row.artist2_name})
MERGE (a1)-[:INFLUENCED_BY]->(a2);

// Artist Influenced On Relationships
LOAD CSV WITH HEADERS FROM 'file:///artist_relationships.csv' AS row
WITH row WHERE row.relationship_type = 'Influenced On'
MATCH (a1:Artist {name: row.artist1_name, birth_year: toInteger(row.birth_year1)})
MATCH (a2:Artist {name: row.artist2_name})
MERGE (a1)-[:INFLUENCED]->(a2);
