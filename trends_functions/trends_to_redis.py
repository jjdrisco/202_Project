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
    Configures Chrome options to impersonate a real browser and initializes a Chrome WebDriver.
    Returns:
        webdriver.Chrome: An instance of Chrome WebDriver configured with the specified options.
    """

    # Configure Chrome options with your profile
    chrome_options = Options()
    
    # Use existing user profile (helps maintain cookies, extensions, etc.)
    chrome_options.add_argument("--user-data-dir=C:\\Users\\{YOUR_USERNAME}\\AppData\\Local\\Google\\Chrome\\User Data")  # Update path
    chrome_options.add_argument("--profile-directory=Your Chrome")  # Update with your profile name
    
    # Add common browser fingerprinting mitigations
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")  # Prevents detection [[10]]
    chrome_options.add_argument("--start-maximized")  # Start with maximized window
    chrome_options.add_argument("--disable-infobars")  # Disable info bars
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])  # Remove automation flags [[3]]
    chrome_options.add_experimental_option("useAutomationExtension", False)  # Disable automation extension [[10]]
    
    # Add realistic user agent (optional, update with a current one)
    chrome_options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")
    
    # UNCOMMENT TO RUN HEADLESS (with additional settings to make it less detectable)
    # chrome_options.add_argument("--headless=new")  # New headless mode for Chrome v109+ [[3]]
    # chrome_options.add_argument("--window-size=1920,1080")  # Realistic resolution for headless
    # chrome_options.add_argument("--disable-gpu")  # Disable GPU acceleration in headless

    # Initialize Chrome with profile
    driver = webdriver.Chrome(options=chrome_options)
    
    # Execute CDP commands to modify navigator properties (further anti-detection)
    driver.execute_cdp_cmd("Page.addScriptToEvaluateOnNewDocument", {
        "source": """
        Object.defineProperty(navigator, 'webdriver', {
            get: () => undefined
        });
        """
    })

    return driver

def scrape(driver, entity_name):
    """
    Scrapes Google Trends data for a given entity using a hybrid approach of curl impersonation and Selenium.
    Checks for "Interest over time" element and refreshes/fixes if needed.
    
    Args:
        driver (selenium.webdriver): The Selenium WebDriver instance used for browser automation.
        entity_name (str): The name of the entity (e.g., artist, topic) to search for on Google Trends.
    
    Raises:
        Exception: If an error occurs during the scraping process, it will be caught and printed.
    """

    try:
        # Open the Google Trends homepage
        url = "https://trends.google.com/trends/explore"
        response = get_page_with_curl_impersonate(url)
        
        # Save the response to a temporary HTML file
        with open("trends_page.html", "wb") as f:
            f.write(response.content)
        
        # Let Selenium load the saved HTML to maintain the curl impersonation
        driver.get("file://" + os.path.abspath("trends_page.html"))
        
        # Use a slightly longer wait time for better reliability
        wait = WebDriverWait(driver, 12)
        
        # Navigate to the actual URL after impersonation prep
        driver.get(url)
        time.sleep(3)
        driver.refresh()
        
        # Wait for the page to load and the search input to be available
        search_input = wait.until(EC.element_to_be_clickable((By.ID, "input-29")))
        
        # Enter the entity name
        search_input.clear()
        search_input.send_keys(entity_name)
        
        # Small delay to allow autocomplete suggestions to appear
        time.sleep(3)
        
        # Try to get autocomplete suggestions with error handling
        try:
            suggestions = wait.until(EC.presence_of_all_elements_located(
                (By.CSS_SELECTOR, "md-virtual-repeat-container md-autocomplete-parent-scope")
            ))
            
            # Click the second suggestion if available
            if len(suggestions) >= 2:
                suggestions[1].click()
            else:
                # Fallback: press Enter to search with the entered text
                search_input.send_keys(Keys.RETURN)
        except Exception as e:
            print(f"Could not find suggestions, using direct search: {e}")
            search_input.send_keys(Keys.RETURN)
        
        # Wait for the search results to load
        time.sleep(5)
        
        # Check if "Interest over time" element is present
        interest_over_time_present = False
        try:
            interest_element = wait.until(EC.presence_of_element_located(
                (By.XPATH, "//div[contains(@class, 'fe-line-chart-header-title') and contains(text(), 'Interest over')]")
            ))
            interest_over_time_present = True
            print("Interest over time chart is present - data loaded successfully!")
        except:
            interest_over_time_present = False
            print("Interest over time chart not found - trying refresh...")
            
            # First simply try refreshing the page
            driver.refresh()
            time.sleep(5)
            
            # Check again after refresh
            try:
                interest_element = wait.until(EC.presence_of_element_located(
                    (By.XPATH, "//div[contains(@class, 'fe-line-chart-header-title') and contains(text(), 'Interest over')]")
                ))
                interest_over_time_present = True
                print("Interest over time chart appeared after refresh!")
            except:
                interest_over_time_present = False
                print("Interest over time chart still not found after refresh - will try time range fix...")
                
                # Try the time range fix if refresh didn't work
                try:
                    # Find and click the time range dropdown
                    dropdown_button = wait.until(EC.element_to_be_clickable(
                        (By.CSS_SELECTOR, "md-select[aria-label*='Select time period']")
                    ))
                    dropdown_button.click()
                    time.sleep(2)
                    
                    # Try to find and click "Past hour" option by ID
                    try:
                        past_hour_option = wait.until(EC.element_to_be_clickable((By.ID, "select_option_14")))
                        past_hour_option.click()
                        print("Selected 'Past hour' time range")
                        time.sleep(5)
                    except:
                        # Try JavaScript if direct click fails
                        script = """
                        var options = document.querySelectorAll('md-option');
                        for(var i=0; i<options.length; i++) {
                            if(options[i].textContent.includes('Past hour')) {
                                options[i].click();
                                return true;
                            }
                        }
                        return false;
                        """
                        driver.execute_script(script)
                        print("Used JavaScript to select 'Past hour'")
                        time.sleep(5)
                    
                    # Check if data loaded with new time range
                    try:
                        interest_element = wait.until(EC.presence_of_element_located(
                            (By.XPATH, "//div[contains(@class, 'fe-line-chart-header-title') and contains(text(), 'Interest over')]")
                        ))
                        interest_over_time_present = True
                        print("Interest over time chart appeared after changing time range!")
                        
                        # Now switch back to Past 12 months
                        dropdown_button = wait.until(EC.element_to_be_clickable(
                            (By.CSS_SELECTOR, "md-select[aria-label*='Select time period']")
                        ))
                        dropdown_button.click()
                        time.sleep(2)
                        
                        try:
                            past_12_months = wait.until(EC.element_to_be_clickable((By.ID, "select_option_13")))
                            past_12_months.click()
                            print("Switched back to 'Past 12 months'")
                            time.sleep(5)
                        except:
                            # Try JavaScript if direct click fails
                            script = """
                            var options = document.querySelectorAll('md-option');
                            for(var i=0; i<options.length; i++) {
                                if(options[i].textContent.includes('Past 12 months')) {
                                    options[i].click();
                                    return true;
                                }
                            }
                            return false;
                            """
                            driver.execute_script(script)
                            print("Used JavaScript to select 'Past 12 months'")
                            time.sleep(5)
                    except:
                        print("Interest over time chart still not appearing")
                except Exception as e:
                    print(f"Error during time range fix: {e}")
        
        # Final check for data availability
        if not interest_over_time_present:
            try:
                interest_element = wait.until(EC.presence_of_element_located(
                    (By.XPATH, "//div[contains(@class, 'fe-line-chart-header-title') and contains(text(), 'Interest over')]")
                ))
                interest_over_time_present = True
                print("Interest over time chart is now present - proceeding with export")
            except:
                print("Final check: Interest over time chart not found")
        
        # Only attempt export if data seems to be available, or try anyway as last resort
        if interest_over_time_present or True:  # Always try, but log the situation
            try:
                # Find and click the "Export" button
                export_button = wait.until(EC.element_to_be_clickable(
                    (By.CSS_SELECTOR, "button.widget-actions-item.export")
                ))
                export_button.click()
                
                # Wait for the file to download
                print(f"Downloading search activity data for '{entity_name}'...")
                time.sleep(10)
            except Exception as e:
                print(f"Could not find or click export button: {e}")
                
                # Try alternative approach to find export button
                try:
                    export_buttons = driver.find_elements(By.XPATH, "//button[contains(@class, 'export')]")
                    if export_buttons:
                        export_buttons[0].click()
                        print("Found export button via alternative method")
                        time.sleep(10)
                    else:
                        print("Could not find export button")
                except Exception as e2:
                    print(f"Alternative export button attempt failed: {e2}")
        
    except Exception as e:
        print(f"An error occurred while accessing Google Trends: {e}")

    finally:
        driver.quit()

def process_scrape(download_path, file_name, entity_name):
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
    csv_file = f"{download_path}/{file_name}"
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
    - entity_id: String, the unique identifier of the entity (e.g., 'Vincent_van_Gogh_{birthday}')
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
    """
    Retrieve data from Redis for a given entity type and entity ID.
    This function connects to a Redis database, retrieves data associated with
    the specified entity type and entity ID, and converts the data into a pandas
    DataFrame.
    Args:
        entity_type (str): The type of the entity (e.g., 'user', 'product').
        entity_id (str): The unique identifier of the entity.
    Returns:
        pd.DataFrame: A DataFrame containing the retrieved data with columns
                      'Week' and 'Popularity'. The 'Week' column is converted
                      to datetime, and the 'Popularity' column is converted to
                      numeric values.
    Raises:
        ConnectionError: If the connection to Redis fails.
        ValueError: If the retrieved data cannot be converted to a DataFrame.
    Example:
        >>> df = retreive_from_redis('product', '12345')
        Retrieved 10 data points for trends:product:12345
        2021-01-01: 100
        2021-01-08: 150
        2021-01-15: 200
        2021-01-22: 250
        2021-01-29: 300
        >>> print(df.head())
                  Week  Popularity
        0  2021-01-01         100
        1  2021-01-08         150
        2  2021-01-15         200
        3  2021-01-22         250
        4  2021-01-29         300
    """

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

def scrape_entity(entity_name, entity_type, entity_id, DOWNLOADS_FOLDER_FP):
    """ 
    Scrape Google Trends for entity data and save to Redis 
    Returns dataframe from redis
    """
    try:
        df = retreive_from_redis(entity_type, entity_id)
        if df.shape[0] == 0:
            raise Exception("No data in Redis")
        print("Data found in Redis")
    except:
        attempts = 0
        while attempts < 3:
            try:
                print("Downloading from Google Trends")

                driver =  configure_and_initialize()
                scrape(driver, entity_name)
                df =  process_scrape(DOWNLOADS_FOLDER_FP, "multiTimeline.csv", entity_name)
                insert_trend_data_from_dataframe(df, entity_type, entity_id)

                df = retreive_from_redis(entity_type, entity_id)
                if df.shape[0] != 0:
                    attempts = 3
                    print("Data downloaded from Google Trends")
                else:
                    attempts += 1
            except:
                attempts += 1
                print("Failed to download data from Google Trends")

    finally:
        if df.shape[0] != 0:
            return df
        else:
            return None
    