
import urllib.request
import json
import re
from uuid import uuid4

def clean_html(raw_html):
    if not raw_html:
        return ""
    cleanr = re.compile('<.*?>')
    cleantext = re.sub(cleanr, '', raw_html)
    return cleantext.strip().replace('&nbsp;', ' ').replace('&amp;', '&').replace('&#8211;', '-').replace('&#038;', '&').replace('&#036;', '$')

def determine_type(title, description):
    t = title.lower()
    d = description.lower()
    
    if "sh" in t or "hypochlorite" in t or "bleach" in t:
        return ".sh"
    if "acid" in t or "aluminum" in t or "brightener" in t:
        return ".acid"
    if "degreaser" in t or "hydroxide" in t or "caustic" in t or "degrease" in d:
        return ".degreaser"
    if "rust" in t or "restoration" in t:
        return ".rustRemover"
    if "surfactant" in t or "soap" in t or "detergent" in t:
        return ".surfactant"
    if "neutralizer" in t:
        return ".neutralizer"
    if "seal" in t or "sealer" in t:
        return ".surfaceSealer"
    if "stain" in t or "oil" in t:
        return ".specialtyStain"
    if "window" in t or "glass" in t:
        return ".window"
    if "graffiti" in t or "paint" in t:
        return ".graffiti"
    
    return ".other"

def fetch_products():
    url = "https://powerwash.com/wp-json/wp/v2/product?product_cat=3548&per_page=100"
    all_products = []
    page = 1
    
    headers = {'User-Agent': 'Mozilla/5.0'} 
    
    while True:
        # print(f"Fetching page {page}...") # Commented out to avoid contaminating stdout
        try:
            req = urllib.request.Request(f"{url}&page={page}", headers=headers)
            with urllib.request.urlopen(req) as response:
                if response.status != 200:
                    break
                data = json.loads(response.read().decode())
                if not data:
                    break
                all_products.extend(data)
                page += 1
        except Exception as e:
            # print(f"Error fetching page {page}: {e}") # Commented out to avoid contaminating stdout
            break
            
    return all_products

def generate_swift():
    products = fetch_products()
    
    print("import Foundation")
    print("")
    print("extension ChemicalData {")
    print("    static let powerWashChemicals: [Chemical] = [")
    
    seen_titles = set()
    
    for p in products:
        title = p.get('title', {}).get('rendered', '')
        title = clean_html(title)
        
        if not title or title in seen_titles:
            continue
        
        # Filter unwanted items
        title_lower = title.lower()
        if "kit" in title_lower or "system" in title_lower or "pump" in title_lower or "skid" in title_lower:
            continue
            
        seen_titles.add(title)
        
        content = p.get('content', {}).get('rendered', '')
        excerpt = p.get('excerpt', {}).get('rendered', '')
        description = clean_html(content if content else excerpt)
        # Truncate description
        description = (description[:200] + '...') if len(description) > 200 else description
        description = description.replace('"', '\\"').replace('\n', ' ')
        
        chem_type = determine_type(title, description)
        
        # Uses - extracting from description simply
        uses = ["General purpose"]
        if "roof" in description.lower():
            uses.append("Asphalt shingles")
        if "concrete" in description.lower() or "driveway" in description.lower():
            uses.append("Concrete cleaning")
        if "wood" in description.lower() or "deck" in description.lower():
            uses.append("Wood restoration")
            
        print(f"        Chemical(")
        print(f"            id: UUID(),")
        safe_title = title.replace('"', '\\"')
        print(f"            name: \"{safe_title}\",")
        print(f"            type: {chem_type},")
        print(f"            description: \"{description}\",")
        print(f"            uses: {json.dumps(uses)},")
        print(f"            warnings: [],") 
        print(f"            isBrandName: true,")
        print(f"            mixingStrategy: nil")
        print(f"        ),")

    print("    ]")
    print("}")

if __name__ == "__main__":
    generate_swift()
