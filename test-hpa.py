import requests
import json
import time

url = "https://unity-store-dev-web-server.k8s.stav-devops.eu-central-1.pre-prod.stavco9.com/purchase"

payload = json.dumps({
  "username": "stavtest",
  "maxItemPrice": 50
})
headers = {
  'Content-Type': 'application/json'
}

count = 0

while True:
    response = requests.request("POST", url, headers=headers, data=payload)
    time.sleep(0.1)
    count += 1
    if count % 10 == 0:
        print(f"Request {count} sent")
        if response:
            print(response.json())