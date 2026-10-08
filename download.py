import urllib.request
import os

os.makedirs('assets/sounds', exist_ok=True)
url = "https://actions.google.com/sounds/v1/animals/dog_barking.ogg"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as response:
        with open('assets/sounds/dog_bark.ogg', 'wb') as f:
            f.write(response.read())
    print("Download successful")
except Exception as e:
    print(f"Error: {e}")
