-- Artists Table with Generated Column for NULL birth years
CREATE TABLE Artists (
  artist_name TEXT NOT NULL,
  birth_year INT NULL,
  nationality TEXT,
  citizenship TEXT,
  gender TEXT,
  death_year INT,
  career_start_year INT,
  career_end_year INT,
  birth_year_key INT GENERATED ALWAYS AS (COALESCE(birth_year, -999999)) STORED
);

-- Add primary key using the generated column
ALTER TABLE Artists ADD PRIMARY KEY (artist_name, birth_year_key);

-- Add a partial unique constraint for artists with NULL birth years
-- This ensures that no two artists with NULL birth years can have the same name
CREATE UNIQUE INDEX unique_artist_name_if_null_birth_year 
ON Artists (artist_name) 
WHERE birth_year IS NULL;

-- Places Table
CREATE TABLE Places (
  place_name TEXT PRIMARY KEY
);

-- Artist_Birth_Places Many-to-Many Table
CREATE TABLE Artist_Birth_Places (
  artist_name TEXT NOT NULL,
  birth_year INT,
  birth_year_key INT GENERATED ALWAYS AS (COALESCE(birth_year, -999999)) STORED,
  place_name TEXT NOT NULL,
  PRIMARY KEY (artist_name, birth_year_key, place_name),
  FOREIGN KEY (artist_name, birth_year_key) REFERENCES Artists(artist_name, birth_year_key) ON DELETE CASCADE,
  FOREIGN KEY (place_name) REFERENCES Places(place_name) ON DELETE CASCADE
);

-- Artist_Death_Places Many-to-Many Table
CREATE TABLE Artist_Death_Places (
  artist_name TEXT NOT NULL,
  death_year INT,
  death_year_key INT GENERATED ALWAYS AS (COALESCE(death_year, -999999)) STORED,
  place_name TEXT NOT NULL,
  PRIMARY KEY (artist_name, death_year_key, place_name),
  FOREIGN KEY (artist_name, death_year_key) REFERENCES Artists(artist_name, birth_year_key) ON DELETE CASCADE,
  FOREIGN KEY (place_name) REFERENCES Places(place_name) ON DELETE CASCADE
);

-- Occupations Table
CREATE TABLE Occupations (
  occupation_name TEXT PRIMARY KEY
);

-- Artist_Occupations Many-to-Many Table
CREATE TABLE Artist_Occupations (
  artist_name TEXT NOT NULL,
  birth_year INT,
  birth_year_key INT GENERATED ALWAYS AS (COALESCE(birth_year, -999999)) STORED,
  occupation_name TEXT NOT NULL,
  PRIMARY KEY (artist_name, birth_year_key, occupation_name),
  FOREIGN KEY (artist_name, birth_year_key) REFERENCES Artists(artist_name, birth_year_key) ON DELETE CASCADE,
  FOREIGN KEY (occupation_name) REFERENCES Occupations(occupation_name) ON DELETE CASCADE
);

-- Schools Table
CREATE TABLE Schools (
  school_name TEXT PRIMARY KEY
);

-- Artist_Schools Many-to-many table
CREATE TABLE Artist_Schools (
  artist_name TEXT NOT NULL,
  birth_year INT,
  birth_year_key INT GENERATED ALWAYS AS (COALESCE(birth_year, -999999)) STORED,
  school_name TEXT NOT NULL,
  time_period JSONB,
  PRIMARY KEY (artist_name, birth_year_key, school_name),
  FOREIGN KEY (artist_name, birth_year_key) REFERENCES Artists(artist_name, birth_year_key) ON DELETE CASCADE,
  FOREIGN KEY (school_name) REFERENCES Schools(school_name) ON DELETE CASCADE
);

-- Artworks Table with Composite Primary Key
CREATE TABLE Artworks (
  title TEXT NOT NULL,
  artwork_date INT NOT NULL,
  medium TEXT,
  department TEXT,
  date_acquired DATE,
  art_classification TEXT,
  credit_line TEXT,
  exhibition_location TEXT,
  PRIMARY KEY (title, artwork_date)
);

-- Add an index on the Artworks primary key
CREATE INDEX idx_artworks_title_date ON Artworks(title, artwork_date);

-- Artworks_Artists Many-to-Many Table
CREATE TABLE Artworks_Artists (
  title TEXT NOT NULL,
  artwork_date INT NOT NULL,
  artist_name TEXT NOT NULL,
  birth_year INT,
  birth_year_key INT GENERATED ALWAYS AS (COALESCE(birth_year, -999999)) STORED,
  PRIMARY KEY (title, artwork_date, artist_name, birth_year_key),
  FOREIGN KEY (title, artwork_date) REFERENCES Artworks(title, artwork_date) ON DELETE CASCADE,
  FOREIGN KEY (artist_name, birth_year_key) REFERENCES Artists(artist_name, birth_year_key) ON DELETE CASCADE
);

-- Movements Table
CREATE TABLE Movements (
  movement_name TEXT PRIMARY KEY
);

-- Artist_Movements Many-to-Many Table
CREATE TABLE Artist_Movements (
  artist_name TEXT NOT NULL,
  birth_year INT,
  birth_year_key INT GENERATED ALWAYS AS (COALESCE(birth_year, -999999)) STORED,
  movement_name TEXT NOT NULL,
  PRIMARY KEY (artist_name, birth_year_key, movement_name),
  FOREIGN KEY (artist_name, birth_year_key) REFERENCES Artists(artist_name, birth_year_key) ON DELETE CASCADE,
  FOREIGN KEY (movement_name) REFERENCES Movements(movement_name) ON DELETE CASCADE
);

-- Styles Table
CREATE TABLE Styles (
  style_name TEXT PRIMARY KEY
);

-- Artist_Styles Many-to-Many Table
CREATE TABLE Artist_Styles (
  artist_name TEXT NOT NULL,
  birth_year INT,
  birth_year_key INT GENERATED ALWAYS AS (COALESCE(birth_year, -999999)) STORED,
  style_name TEXT NOT NULL,
  style_count INT,
  style_years TEXT,
  PRIMARY KEY (artist_name, birth_year_key, style_name),
  FOREIGN KEY (artist_name, birth_year_key) REFERENCES Artists(artist_name, birth_year_key) ON DELETE CASCADE,
  FOREIGN KEY (style_name) REFERENCES Styles(style_name) ON DELETE CASCADE
);

ALTER TABLE Artist_Styles
ADD CONSTRAINT unique_artist_style UNIQUE (artist_name, birth_year, style_name);

-- Artist Relationships Table (Teachers/Pupils/Friends)
CREATE TABLE Artist_Relationships (
  artist1_name TEXT NOT NULL,
  birth_year1 INT,
  birth_year1_key INT GENERATED ALWAYS AS (COALESCE(birth_year1, -999999)) STORED,
  artist2_name TEXT NOT NULL,
  relationship_type TEXT CHECK (relationship_type IN ('Pupil', 'Teacher', 'Friend', 'Influenced By', 'Influenced On')),
  PRIMARY KEY (artist1_name, birth_year1_key, artist2_name, relationship_type),
  FOREIGN KEY (artist1_name, birth_year1_key) REFERENCES Artists(artist_name, birth_year_key) ON DELETE CASCADE,
  -- Prevent self-relationships
  CONSTRAINT no_self_relationship CHECK (artist1_name != artist2_name)
);
