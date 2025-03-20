# Global Art Exploration and Analysis

*By: John Driscoll, Taylor Martinez, Thuy Nguyen*

**Presentation Video**: https://www.youtube.com/watch?v=A9CCB9pImhM

Abstract:

This research employs an innovative multi-database architecture (PostgreSQL, Neo4j, Redis) integrating the MoMA dataset, PainterPalette, WikiData, and Google Trends to analyze artistic influence networks and public engagement patterns. Our investigation into whether prolific artists from influential movements trend together revealed that artists within the same movement rarely share popularity trends, with unexpected cross-movement correlations. Recent artist passings create measurable popularity ripples across their professional networks, with immediate and delayed effects on connected artists. Additional investigation into the impacts of the Los Angeles wildfires shows that physical cultural repositories generate distinct public engagement patterns compared to individual artists during crises. This work demonstrates how specialized database integration enables complex cultural analytics that reveal nuanced patterns of artistic influence, legacy propagation, and public engagement with cultural heritage.
<br/><br/>

Other Resources:
| Resource | Location |
|----------|----------|
| Presentation Slides | See "Presentation_Slides.pdf" |
| Written Report | See "Global_Art_Exploration_And_Analysis.pdf" |
| Examples and Use Cases | See folder "example_usage/" for questions we implemented and answered with this tool |

---

**Replication Instructions:**

Use requirements.txt to create an environment using:
$ conda create --name <env> --file requirements.txt
or pip install the included requirements

Replicating Postgres:
1. Install Postgres
2. Create a new Postgres db instance
3. Run “psql -U <username> -d <dbname> < db_dump.sql” in your terminal
Note: psql might not be in your path by default. Fix this by running "export PATH="$PATH:/Library/PostgreSQL/<YOUR VERSION>/bin"
   
Replicating Neo4j:
1. Install Neo4j
2. Create new graph db instance
3. Add in apoc and graph data science library plugins
4. Copy all files from git folder “neo4j_csv_files/” into Neo4j database’s import folder
5. Run the file “neo4j_csv_files/create_neo4j_db.cypher” by pasting its contents into a Neo4j desktop browser cell or by executing in a neo4j terminal of your choice

Replicating Redis:
1. Install Redis Community
2. In your command prompt navigate to folder "redis_dump/" in this project on your device
3. Run “redis-server redis.conf --dbfilename dump.rdb --appendonly yes” in your command line

Enabling Web Scraping:
1. Download Google Chrome
Note: Web Scraping is inconsistent due to Google Trends' Anti-Scraping implementation.

Replication Notes:
- The Postgres dump can be rebuilt from scratch by running "data_processing/initial_data_processing.ipynb", "data_processing/data_augmentation.ipynb", and "data_processing/clean_and_import.ipynb" in order and following the contained instructions.
- The files required for Neo4j can be rebuilt by exporting each table from Postgres as a csv with headers.
- The redis dump can be rebuilt from scratch by scraping and inserting all interested entities using functions in "trends_functions/trends_to_redis.py"
