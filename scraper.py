import requests
from bs4 import BeautifulSoup
import json
import re
import os

# Scraper data flow: scrape_soccer_benchmarks -> parse_benchmark_value -> post_process_benchmarks

def clean_text(text):
    if not text:
        return ""
    return re.sub(r'\s+', ' ', text).strip()

def parse_benchmark_value(raw_value, category, test_name):
    """
    Takes a raw string like "Sub 4.6 seconds" or "18-20 inches" 
    and returns a tuple of (min_value, max_value) as floats.
    """
    if not raw_value or raw_value == "N/A":
        return None, None
        
    val_lower = raw_value.lower()
    
    # 1. Look for "Sub X" or "< X" (This means X is the MAXIMUM allowed)
    match_sub = re.search(r'(?:sub|<)\s*([\d\.]+)', val_lower)
    if match_sub:
        return None, float(match_sub.group(1))

    # 2. Look for "Over X" or "> X" or "X+" (This means X is the MINIMUM allowed)
    match_over = re.search(r'(?:over|>)\s*([\d\.]+)', val_lower)
    if match_over:
        return float(match_over.group(1)), None
    
    # 3. Look for a Range "X - Y" or "X to Y"
    match_range = re.search(r'([\d\.]+)\s*(?:-|to)\s*([\d\.]+)', val_lower)
    if match_range:
        return float(match_range.group(1)), float(match_range.group(2))

    # 4. Example: "20+" or "3000m+" -> min=20.0, min=3000.0
    match_plus = re.search(r'([\d\.]+)[a-z]*\s*\+', val_lower)
    if match_plus:
        return float(match_plus.group(1)), None

    # 5. Look for just a single number "X"
    match_num = re.search(r'([\d\.]+)', val_lower)
    if match_num:
        val = float(match_num.group(1))
        
        # If it's just a single number, we need to decide if it's a min or max based on the test type.
        if category in ["Speed and Acceleration", "Agility and Quickness"]:
            return None, val
        else:
            return val, None

    return None, None

def post_process_benchmarks(data):
    """
    Fills in the missing threshold_min and threshold_max by looking at 
    the adjacent division's requirements.
    """
    grouped = {}
    for item in data:
        key = (item['category'], item['test_name'])
        if key not in grouped:
            grouped[key] = {}
        grouped[key][item['division']] = item
        
    for key, divs in grouped.items():
        d1 = divs.get("Division 1")
        d2 = divs.get("Division 2")
        d3 = divs.get("Division 3")
        
        cat = key[0]
        
        # Tests where lower time/score is better (Speed, Agility)
        if cat in ["Speed and Acceleration", "Agility and Quickness"]:
            # D2 Min becomes D1 Max
            if d1 and d2 and d1.get('threshold_max') is not None and d2.get('threshold_min') is None:
                d2['threshold_min'] = d1['threshold_max']
            # D3 Min becomes D2 Max
            if d2 and d3 and d2.get('threshold_max') is not None and d3.get('threshold_min') is None:
                d3['threshold_min'] = d2['threshold_max']
                
        # Tests where higher score is better (Strength, Endurance, Power)
        else:
            # D2 Max becomes D1 Min
            if d1 and d2 and d1.get('threshold_min') is not None and d2.get('threshold_max') is None:
                d2['threshold_max'] = d1['threshold_min']
            # D3 Max becomes D2 Min
            if d2 and d3 and d2.get('threshold_min') is not None and d3.get('threshold_max') is None:
                d3['threshold_max'] = d2['threshold_min']
                
    return data

def scrape_soccer_benchmarks():
    url = "https://web.archive.org/web/20250613124032/https://soccertalented.com/measuring-soccer-performance-with-physical-tests/"
    
    print(f"Fetching {url}...")
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Error fetching URL: {e}")
        return None

    soup = BeautifulSoup(response.content, 'html.parser')
    
    target_categories = [
        "Speed and Acceleration",
        "Explosiveness and Power",
        "Agility and Quickness",
        "Endurance and Aerobic Capacity",
        "Physical Strength and Endurance Circuit"
    ]
    
    organized_data = []
    
    # Find all potential headers
    for element in soup.find_all(['h1', 'h2', 'h3', 'h4', 'strong', 'b']):
        text = clean_text(element.get_text())
        
        matched_category = None
        for cat in target_categories:
            if cat.lower() in text.lower():
                matched_category = cat
                break
        
        if matched_category:
            next_header = None
            current = element.find_next()
            while current:
                if current.name in ['h1', 'h2', 'h3', 'h4']:
                    curr_text = clean_text(current.get_text())
                    if any(c.lower() in curr_text.lower() for c in target_categories):
                        next_header = current
                        break
                current = current.find_next()
            
            current_node = element.find_next()
            while current_node and current_node != next_header:
                if current_node.name == 'ul':
                    for li in current_node.find_all('li', recursive=False):
                        strong_tag = li.find('strong')
                        if not strong_tag:
                            continue

                        test_name = clean_text(strong_tag.get_text()).rstrip(':')
                        
                        nested_list = li.find('ul')
                        if nested_list:
                            for nested_li in nested_list.find_all('li'):
                                li_text = clean_text(nested_li.get_text())

                                parts = li_text.split(':')
                                if len(parts) < 2:
                                    continue
                                raw_value = parts[-1].strip()

                                division = None
                                if re.search(r'division\s+(i|1)\b', li_text, re.IGNORECASE):
                                    division = "Division 1"
                                elif re.search(r'division\s+(ii|2)\b', li_text, re.IGNORECASE):
                                    division = "Division 2"
                                elif re.search(r'division\s+(iii|3)\b', li_text, re.IGNORECASE):
                                    division = "Division 3"

                                if division and raw_value != "N/A":
                                    min_val, max_val = parse_benchmark_value(raw_value, matched_category, test_name)

                                    # rather than gathering results in feet, we gather the result in meters (cooper test lists both in raw_value)
                                    if 'cooper' in test_name.lower():
                                        if 'feet' in raw_value.lower() or 'ft' in raw_value.lower():
                                            if min_val: min_val = round(min_val * 0.3048, 1)
                                            if max_val: max_val = round(max_val * 0.3048, 1)
                                            raw_value = raw_value.replace('feet', 'meters').replace('ft', 'm')
                                    
                                    # Specific rule: For Division 1 in Physical Strength, there should be no max threshold
                                    if division == "Division 1" and matched_category == "Physical Strength and Endurance Circuit":
                                        max_val = None
                                    
                                    # NEW RULE: For Division 1 in Explosiveness, there should be no max threshold
                                    if division == "Division 1" and matched_category == "Explosiveness and Power":
                                        max_val = None

                                    organized_data.append({
                                        "division": division,
                                        "category": matched_category,
                                        "test_name": test_name,
                                        "raw_value": raw_value,
                                        "threshold_min": min_val,
                                        "threshold_max": max_val
                                    })
                
                current_node = current_node.find_next()

    # Pass the data through the post-processor to fill in the missing range values
    organized_data = post_process_benchmarks(organized_data)

    return organized_data

# sends scraped data to the database using the API endpoint

if __name__ == "__main__":
    print("Starting Web Scraper...")
    benchmarks = scrape_soccer_benchmarks()
    
    if benchmarks:
        print(f"✅ Successfully scraped {len(benchmarks)} benchmarks.")

        api_url = "http://127.0.0.1:8000/api/benchmarks/"
        
        success_count = 0
        fail_count = 0
        
        print(f"\nPosting data to {api_url}...")
        
        for benchmark in benchmarks:
            try:
                # Send a POST request to the API for each benchmark
                # The .post() method automatically converts the dict to JSON
                response = requests.post(api_url, json=benchmark)
                
                # Check if the request was successful (200 OK or 201 Created)
                if response.status_code in [200, 201]:
                    print(f"  -> Successfully posted: {benchmark['division']} - {benchmark['test_name']}")
                    success_count += 1
                else:
                    # Print an error if the API returned a problem
                    print(f"  -> ❌ FAILED to post: {benchmark['division']} - {benchmark['test_name']}")
                    print(f"     Status: {response.status_code}, Response: {response.text}")
                    fail_count += 1
            except requests.RequestException as e:
                print(f"  -> ❌ NETWORK ERROR posting: {benchmark['division']} - {benchmark['test_name']}")
                print(f"     Error: {e}")
                fail_count += 1

        print("\n--- Scraping and Posting Complete ---")
        print(f"✅ Successful posts: {success_count}")
        print(f"❌ Failed posts: {fail_count}")
        
        if fail_count == 0:
            print("\nAll benchmarks posted successfully!")
        else:
            print("\nSome benchmarks failed to post. Check the errors above.")
            
    else:
        print("❌ Scraper failed to return any data.")
