import pandas as pd
import numpy as np
import time
import os

# Import scraping
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys

# Import curl_cffi for TLS fingerprint impersonation
from curl_cffi import requests
#from curl_cffi.impersonate import ImpersonateConfig

# for question answering
from datetime import datetime, timedelta

# for redis
import redis

def delete_file(file_path):
    """Delete a file from the specified path"""
    try:
        # Check if the file exists
        if os.path.exists(file_path):
            # Delete the file
            os.remove(file_path)
            print(f"Successfully deleted: {file_path}")
        else:
            print(f"File not found: {file_path}")
    except Exception as e:
        print(f"Error deleting file: {e}")

def get_page_with_curl_impersonate(url, browser="chrome110"):
    """
    Fetch a page using curl_cffi with browser impersonation
    """
    #config = ImpersonateConfig(browser)
    session = requests.Session(impersonate=browser)
    
    # Add headers to better impersonate the browser
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
        "Accept-Encoding": "gzip, deflate, br",
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "none",
        "Sec-Fetch-User": "?1",
    }
    
    response = session.get(url, headers=headers)
    return response

def configure_and_initialize():
    """
    Configures Chrome options with a specified user profile and initializes a headless Chrome WebDriver.
    Returns:
        webdriver.Chrome: An instance of Chrome WebDriver configured with the specified options.
    """

    # Configure Chrome options with your profile
    chrome_options = Options()
    chrome_options.add_argument("--user-data-dir=C:\\Users\\{YOUR_USERNAME}\\AppData\\Local\\Google\\Chrome\\User Data")  # Update path
    chrome_options.add_argument("--profile-directory=Default")  # Update with your profile name
    # UNCOMMENT TO RUN HEADLESS
    #chrome_options.add_argument("--headless")

    # Initialize Chrome with profile
    driver = webdriver.Chrome(options=chrome_options)

    return driver

def scrape(driver, entity_name):
    """
    Scrapes Google Trends data for a given entity using a hybrid approach of curl impersonation and Selenium.
    Args:
        driver (selenium.webdriver): The Selenium WebDriver instance used for browser automation.
        entity_name (str): The name of the entity (e.g., artist, topic) to search for on Google Trends.
    Raises:
        Exception: If an error occurs during the scraping process, it will be caught and printed.
    Notes:
        - This function first uses curl impersonation to fetch the Google Trends homepage and saves it as a temporary HTML file.
        - Selenium then loads this saved HTML file to maintain the curl impersonation while still allowing for interaction.
        - The function navigates to the Google Trends search page, enters the entity name, and selects the second autocomplete suggestion if available.
        - Finally, it clicks the "Export" button to download the search activity data for the specified entity.
    """

    try:
        # Open the Google Trends homepage
        url = "https://trends.google.com/trends/explore"
        response = get_page_with_curl_impersonate(url)
        #driver.post(url)
        
        # Save the response to a temporary HTML file
        with open("trends_page.html", "wb") as f:
            f.write(response.content)
        
        # Let Selenium load the saved HTML to maintain the curl impersonation
        # but still use Selenium for interaction
        driver.get("file://" + os.path.abspath("trends_page.html"))
        
        # For subsequent navigation, we'll use a hybrid approach
        # Now proceed with the normal Selenium interaction
        wait = WebDriverWait(driver, 10)
        
        # Navigate to the actual URL after impersonation prep
        driver.get(url)
        
        # Wait for the page to load and the search input to be available
        search_input = wait.until(EC.element_to_be_clickable((By.ID, "input-29")))
        
        # Enter the artist name
        search_input.send_keys(entity_name)
        
        # Small delay to allow autocomplete suggestions to appear
        time.sleep(2)
        
        # Wait for autocomplete suggestions and click the second option
        suggestions = wait.until(EC.presence_of_all_elements_located(
            (By.CSS_SELECTOR, "md-virtual-repeat-container md-autocomplete-parent-scope")
        ))
        
        # Click the second suggestion if available
        if len(suggestions) >= 2:
            suggestions[1].click()
        else:
            # Fallback: press Enter to search with the entered text
            search_input.send_keys(Keys.RETURN)
        
        # Wait for the search results to load
        time.sleep(5)
        
        # Find and click the "Export" button
        export_button = wait.until(EC.element_to_be_clickable(
            (By.CSS_SELECTOR, "button.widget-actions-item.export")
        ))
        export_button.click()
        
        # Wait for the file to download
        print(f"Downloading search activity data for '{entity_name}'...")
        time.sleep(10)
        
    except Exception as e:
        print(f"An error occurred while accessing google trends: {e}")

    finally:
        driver.quit()

def process_scrape(download_path, entity_name):
    """
    Processes a CSV file containing Google Trends data and prints the data.

    Args:
        download_path (str): The file path to the directory containing the CSV file.
        entity_name (str): The name of the entity for which the trend data is being processed.

    Returns:
        None

    This function performs the following steps:
        1. Constructs the file path to the CSV file named 'multiTimeline.csv' within the given download path.
        2. Loads the CSV file into a Pandas DataFrame, skipping the first two rows and parsing the 'Week' column as dates.
        3. Prints a sanity check message indicating the trend data that was pulled.
        4. Prints the search activity data for the specified entity.
    """

    # Load the CSV into a Pandas DataFrame
    #download_path = DOWNLOADS_FOLDER_FP  # Update with your downloads path
    csv_file = f"{download_path}/multiTimeline.csv"
    df = pd.read_csv(csv_file, skiprows=2, parse_dates=['Week'])
    delete_file(csv_file)

    # Sanity check on data
    print("Pulled Trend Data for "+df.columns[1])

    # Display the DataFrame
    print(f"Search activity data for '{entity_name}':")
    print(df)

    return df

def connect_to_redis(host='localhost', port=6379, db=0):
    """Connect to a Redis instance."""
    try:
        redis_client = redis.Redis(host=host, port=port, db=db, decode_responses=True)
        # Test the connection
        redis_client.ping()
        print("Successfully connected to Redis")
        return redis_client
    except redis.ConnectionError as e:
        print(f"Failed to connect to Redis: {e}")
        return None
    
def insert_trend_data_from_dataframe(df, entity_type, entity_id):
    """
    Insert trend data from a pandas DataFrame into Redis.
    
    Parameters:
    - df: Pandas DataFrame with columns 'Week' and a data column
    - entity_type: String, either 'artist' or 'artwork'
    - name: String, the name of the entity (e.g., 'Vincent_van_Gogh')
    """
    redis_client = connect_to_redis()
    if not redis_client:
        return
    
    # Create the key using the slug format
    key = f"trends:{entity_type}:{entity_id}"
    
    # Check if DataFrame is not empty
    if df.empty:
        print("DataFrame is empty. No data to insert.")
        return
    
    # Get column names
    columns = df.columns
    if len(columns) < 2 or 'Week' not in df.columns:
        print("DataFrame must contain a 'Week' column and at least one data column.")
        return
    
    # Change week timestamp column back into date string for import
    import_df = df.copy()
    import_df['Week'] = import_df['Week'].dt.strftime('%Y-%m-%d')
    
    # Use pipeline for better performance when inserting multiple values
    with redis_client.pipeline() as pipe:
        # Insert each row of the DataFrame into Redis
        for index, row in import_df.iterrows():
            week_date = row['Week']
            # Assuming the second column contains the trend value
            trend_value = row[columns[1]] if columns[1] != 'Week' else row[columns[0]]
            
            # Store as hash entry
            pipe.hset(key, week_date, int(trend_value))
        
        # Add metadata
        pipe.hset(f"{key}:meta", "type", entity_type)
        pipe.hset(f"{key}:meta", "name", entity_id)
        pipe.hset(f"{key}:meta", "last_updated", datetime.now().isoformat())
        
        # Execute all commands in the pipeline
        pipe.execute()
    
    # Force a save to ensure persistence
    redis_client.save()
    
    print(f"Successfully stored {len(df)} data points for {key}")
    print("Data has been persisted to disk")

def retreive_from_redis(entity_type, entity_id):
    # For retrieving the data
    redis_client = connect_to_redis()
    if redis_client:
        key = f"trends:{entity_type}:{entity_id}"
        data = redis_client.hgetall(key)
        print(f"Retrieved {len(data)} data points for {key}")
        
        # Optional: Print some sample data
        sample_items = list(data.items())[:5]
        for date, value in sample_items:
            print(f"{date}: {value}")

        # convert retrieved data to dataframe
        retreived_df = pd.DataFrame(data.items(), columns=['Week', 'Popularity'])
        #retreived_df['Week'] = retreived_df['Week'].to_timestamp()
        retreived_df['Week'] = pd.to_datetime(retreived_df['Week'])
        retreived_df['Popularity'] = pd.to_numeric(retreived_df['Popularity'])
        
        return retreived_df
    
def main():
    DOWNLOADS_FOLDER_FP = "/Users/***REMOVED***/Downloads/"
    YOUR_USERNAME = "***REMOVED***"
    
    # Artist/Artwork/Movement/Style/Location to search for
    entity_type = "Location"
    entity_name = "The Getty"
    entity_id = 1234

    # scrape and insert data
    driver = configure_and_initialize()
    scrape(driver, entity_name)
    df = process_scrape(DOWNLOADS_FOLDER_FP, entity_name)
    insert_trend_data_from_dataframe(df, entity_type, entity_id)

    # retreive data
    df = retreive_from_redis(entity_type, entity_id)

    # test import & retrieval worked w mock query
    n_weeks = 1
    today = datetime.now()
    one_week_ago = today - timedelta(weeks=n_weeks)
    popularity_last_week = np.mean(df[df['Week'] >= one_week_ago].iloc[:,1].values)
    print(popularity_last_week)

if __name__ == "__main__":
    main()