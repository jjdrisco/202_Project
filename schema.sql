CREATE TABLE Artists (
  artist_id SERIAL PRIMARY KEY,
  display_name TEXT,
  artist_bio TEXT,
  nationality TEXT,
  gender TEXT,
  birth_year INT,
  death_year INT
);

CREATE TABLE Artworks (
  artwork_id SERIAL PRIMARY KEY,
  title TEXT,
  artist_id BIGINT,
  artwork_start_date INT,
  medium TEXT,
  FOREIGN KEY (artist_id) REFERENCES Artists(artist_id) ON DELETE CASCADE
);

CREATE TABLE Movements (
  movement_id SERIAL PRIMARY KEY,
  name TEXT
);

CREATE TABLE Artist_Movements (
  artist_id INT,
  movement_id INT,
  years_active JSONB,
  PRIMARY KEY (artist_id, movement_id),
  FOREIGN KEY (artist_id) REFERENCES Artists(artist_id) ON DELETE CASCADE,
  FOREIGN KEY (movement_id) REFERENCES Movements(movement_id)
);

CREATE TABLE Styles (
  style_id SERIAL PRIMARY KEY,
  name TEXT
);

CREATE TABLE Artist_Styles (
  artist_id INT,
  style_id INT,
  style_count INT,
  style_years JSONB,
  PRIMARY KEY (artist_id, style_id),
  FOREIGN KEY (artist_id) REFERENCES Artists(artist_id) ON DELETE CASCADE,
  FOREIGN KEY (style_id) REFERENCES Styles(style_id)
);

CREATE TABLE Locations (
  location_id SERIAL PRIMARY KEY,
  name TEXT,
  country TEXT
);

CREATE TABLE Artist_Locations (
  artist_id INT,
  location_id INT,
  years_active JSONB,
  PRIMARY KEY (artist_id, location_id),
  FOREIGN KEY (artist_id) REFERENCES Artists(artist_id) ON DELETE CASCADE,
  FOREIGN KEY (location_id) REFERENCES Locations(location_id)
);

CREATE TABLE Influences (
  influencer_id INT,
  influenced_id INT,
  PRIMARY KEY (influencer_id, influenced_id),
  FOREIGN KEY (influencer_id) REFERENCES Artists(artist_id) ON DELETE CASCADE,
  FOREIGN KEY (influenced_id) REFERENCES Artists(artist_id) ON DELETE CASCADE
);

CREATE TABLE Friends (
  artist1_id INT,
  artist2_id INT,
  PRIMARY KEY (artist1_id, artist2_id),
  FOREIGN KEY (artist1_id) REFERENCES Artists(artist_id) ON DELETE CASCADE,
  FOREIGN KEY (artist2_id) REFERENCES Artists(artist_id) ON DELETE CASCADE
);

CREATE TABLE Exhibitions (
  exhibition_id SERIAL PRIMARY KEY,
  location_id INT,
  year INT,
  painting_count INT,
  FOREIGN KEY (location_id) REFERENCES Locations(location_id)
);
