-- Artists Table with Composite Primary Key
CREATE TABLE Artists (
  artist_name TEXT NOT NULL,
  birth_year INT NOT NULL,
  birth_place TEXT,
  death_place TEXT,
  nationality TEXT,
  citizenship TEXT,
  gender TEXT,
  death_year INT,
  career_start_year INT,
  career_end_year INT,
  PRIMARY KEY (artist_name, birth_year) -- Natural key: artist's name and birth year
);

-- Occupations Table (Primary Key: occupation_name)
CREATE TABLE Occupations (
  occupation_name TEXT PRIMARY KEY
);

-- Artist_Occupations Many-to-Many Table
CREATE TABLE Artist_Occupations (
  artist_name TEXT NOT NULL,
  birth_year INT NOT NULL,
  occupation_name TEXT NOT NULL,
  PRIMARY KEY (artist_name, birth_year, occupation_name),
  FOREIGN KEY (artist_name, birth_year) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE,
  FOREIGN KEY (occupation_name) REFERENCES Occupations(occupation_name) ON DELETE CASCADE
);

-- Schools Table (Primary Key: school_name)
CREATE TABLE Schools (
  school_name TEXT PRIMARY KEY
);

-- Artist_School Many-to-many table
-- Create the Many-to-Many Relationship table for Artists and PaintingSchools
CREATE TABLE Artist_Schools (
  artist_name TEXT NOT NULL,
  birth_year INT NOT NULL,
  school_name TEXT NOT NULL,
  time_period JSONB,
  PRIMARY KEY (artist_name, birth_year, school_name),
  FOREIGN KEY (artist_name, birth_year) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE,
  FOREIGN KEY (school_name) REFERENCES Schools(school_name) ON DELETE CASCADE
);

-- Artworks Table with Composite Primary Key
CREATE TABLE Artworks (
  title TEXT NOT NULL,
  artwork_date INT NOT NULL, --clean to remove hyphenated years
  medium TEXT,
  department TEXT,
  date_acquired DATE,
  art_classification TEXT, --(we think this means subject matter?)
  credit_line TEXT,
  PRIMARY KEY (title, artwork_date) -- Natural key: unique title + artwork date
);

-- Add an index on the foreign key (artist_name, birth_year) for better join performance
CREATE INDEX idx_artworks_title_date ON Artworks(title, artwork_date);


-- Artworks_Artists Many-to-Many Table
CREATE TABLE Artworks_Artists (
  title TEXT NOT NULL,
  artwork_date INT NOT NULL,
  artist_name TEXT NOT NULL,
  birth_year INT NOT NULL,
  PRIMARY KEY (title, artwork_date, artist_name, birth_year),
  FOREIGN KEY (title, artwork_date) REFERENCES Artworks(title, artwork_date) ON DELETE CASCADE,
  FOREIGN KEY (artist_name, birth_year) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE
);


-- Movements Table (Primary Key: movement_name)
CREATE TABLE Movements (
  movement_name TEXT PRIMARY KEY
);

-- Many-to-Many Relationship for Artists and Movements
CREATE TABLE Artist_Movements (
  artist_name TEXT NOT NULL,
  birth_year INT NOT NULL,
  movement_name TEXT NOT NULL,
  years_active JSONB,
  PRIMARY KEY (artist_name, birth_year, movement_name),
  FOREIGN KEY (artist_name, birth_year) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE,
  FOREIGN KEY (movement_name) REFERENCES Movements(movement_name) ON DELETE CASCADE
);

-- Styles Table (Primary Key: style_name)
CREATE TABLE Styles (
  style_name TEXT PRIMARY KEY
);

-- Many-to-Many Relationship for Artists and Styles
CREATE TABLE Artist_Styles (
  artist_name TEXT NOT NULL,
  birth_year INT NOT NULL,
  style_name TEXT NOT NULL,
  style_count INT,
  style_years TEXT,
  PRIMARY KEY (artist_name, birth_year, style_name),
  FOREIGN KEY (artist_name, birth_year) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE,
  FOREIGN KEY (style_name) REFERENCES Styles(style_name) ON DELETE CASCADE
);

-- Locations Table (Primary Key: name, country)
CREATE TABLE Locations (
  name TEXT NOT NULL,
  country TEXT NOT NULL,
  PRIMARY KEY (name, country)
);

-- Many-to-Many Relationship for Artists and Locations
CREATE TABLE Artist_Locations (
  artist_name TEXT NOT NULL,
  birth_year INT NOT NULL,
  location_name TEXT NOT NULL,
  country TEXT NOT NULL,
  years_active JSONB,
  PRIMARY KEY (artist_name, birth_year, location_name, country),
  FOREIGN KEY (artist_name, birth_year) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE,
  FOREIGN KEY (location_name, country) REFERENCES Locations(name, country) ON DELETE CASCADE
);

-- Artist Relationships Table (Teachers/Pupils/Friends)
CREATE TABLE Artist_Relationships (
  artist1_name TEXT NOT NULL,
  birth_year1 INT NOT NULL,
  artist2_name TEXT NOT NULL,
  birth_year2 INT NOT NULL,
  relationship_type TEXT CHECK (relationship_type IN ('Pupil', 'Teacher', 'Friend')),
  PRIMARY KEY (artist1_name, birth_year1, artist2_name, birth_year2),
  FOREIGN KEY (artist1_name, birth_year1) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE,
  FOREIGN KEY (artist2_name, birth_year2) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE
);

-- Artist Influences Table (Many-to-Many)
CREATE TABLE Influences (
  influencer_name TEXT NOT NULL,
  influencer_birth_year INT NOT NULL,
  influenced_name TEXT NOT NULL,
  influenced_birth_year INT NOT NULL,
  PRIMARY KEY (influencer_name, influencer_birth_year, influenced_name, influenced_birth_year),
  FOREIGN KEY (influencer_name, influencer_birth_year) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE,
  FOREIGN KEY (influenced_name, influenced_birth_year) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE
);

-- Artist Friendships Table (Many-to-Many)
CREATE TABLE Friends (
  artist1_name TEXT NOT NULL,
  birth_year1 INT NOT NULL,
  artist2_name TEXT NOT NULL,
  birth_year2 INT NOT NULL,
  PRIMARY KEY (artist1_name, birth_year1, artist2_name, birth_year2),
  FOREIGN KEY (artist1_name, birth_year1) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE,
  FOREIGN KEY (artist2_name, birth_year2) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE
);

-- Exhibitions Table with Composite Key
CREATE TABLE Exhibitions (
  exhibition_name TEXT NOT NULL,
  location_name TEXT NOT NULL,
  country TEXT NOT NULL,
  year INT NOT NULL,
  painting_count INT,
  PRIMARY KEY (exhibition_name, location_name, country, year),
  FOREIGN KEY (location_name, country) REFERENCES Locations(name, country)
);

-- Many-to-Many Relationship for Artists in Exhibitions
CREATE TABLE Exhibition_Artists (
  exhibition_name TEXT NOT NULL,
  location_name TEXT NOT NULL,
  country TEXT NOT NULL,
  year INT NOT NULL,
  artist_name TEXT NOT NULL,
  birth_year INT NOT NULL,
  PRIMARY KEY (exhibition_name, location_name, country, year, artist_name, birth_year),
  FOREIGN KEY (exhibition_name, location_name, country, year) REFERENCES Exhibitions(exhibition_name, location_name, country, year) ON DELETE CASCADE,
  FOREIGN KEY (artist_name, birth_year) REFERENCES Artists(artist_name, birth_year) ON DELETE CASCADE
);
