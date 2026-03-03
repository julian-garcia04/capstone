import requests
from bs4 import BeautifulSoup
import json
import re

def clean_text(text):
    if not text:
        return ""
    return re.sub(r'\s+', ' ', text).strip()

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
    
    organized_data = {}
    
    # Find all potential headers
    for element in soup.find_all(['h1', 'h2', 'h3', 'h4', 'strong', 'b']):
        text = clean_text(element.get_text())
        
        matched_category = None
        for cat in target_categories:
            if cat.lower() in text.lower():
                matched_category = cat
                break
        
        if matched_category:
            print(f"Found category header: {matched_category}")
            if matched_category not in organized_data:
                organized_data[matched_category] = {}
            
            # Find the next header to use as a boundary
            next_header = None
            current = element.find_next()
            while current:
                if current.name in ['h1', 'h2', 'h3', 'h4']:
                    # Check if this is one of the target categories
                    curr_text = clean_text(current.get_text())
                    if any(c.lower() in curr_text.lower() for c in target_categories):
                        next_header = current
                        break
                current = current.find_next()
            
            # Find all lists between this header and the next header
            current_node = element.find_next()
            while current_node and current_node != next_header:
                if current_node.name == 'ul':
                    print(f"  -> Found a list under {matched_category}")
                    for li in current_node.find_all('li', recursive=False):
                        strong_tag = li.find('strong')
                        if not strong_tag:
                            continue
                        
                        test_name = clean_text(strong_tag.get_text())
                        test_name = test_name.rstrip(':')
                        
                        print(f"    -> Found test: {test_name}")
                        
                        benchmarks = {
                            "Division 1": "N/A",
                            "Division 2": "N/A",
                            "Division 3": "N/A"
                        }
                        
                        has_benchmarks = False
                        
                        # Look for nested list
                        nested_list = li.find('ul')
                        if nested_list:
                            for nested_li in nested_list.find_all('li'):
                                li_text = clean_text(nested_li.get_text())
                                
                                # Extract value after the last colon
                                parts = li_text.split(':')
                                if len(parts) < 2:
                                    continue
                                value = parts[-1].strip()
                                
                                # Use regex for matching
                                if re.search(r'division\s+(i|1)\b', li_text, re.IGNORECASE):
                                    benchmarks["Division 1"] = value
                                    has_benchmarks = True
                                elif re.search(r'division\s+(ii|2)\b', li_text, re.IGNORECASE):
                                    benchmarks["Division 2"] = value
                                    has_benchmarks = True
                                elif re.search(r'division\s+(iii|3)\b', li_text, re.IGNORECASE):
                                    benchmarks["Division 3"] = value
                                    has_benchmarks = True
                        
                        # Only add if we found at least one benchmark
                        if has_benchmarks:
                            organized_data[matched_category][test_name] = benchmarks
                        else:
                            print(f"      -> Skipping {test_name} (no benchmarks found)")
                
                current_node = current_node.find_next()

    return organized_data

if __name__ == "__main__":
    data = scrape_soccer_benchmarks()
    if data:
        print(json.dumps(data, indent=2))
        print(data["Speed and Acceleration"])