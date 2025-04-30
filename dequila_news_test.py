# A stowaway DAG for other project.
# I didn't want to deploy another airflow instance thats all ....
# For use in dockeroperator
import requests
import json
import time
import argparse
from common import get_els_client
from dotenv import load_dotenv
import os

if __name__ == "__main__":
    # Get ticker name as argument
    parser = argparse.ArgumentParser(description="Processes each crypto")
    parser.add_argument("ticker", help="the ticker of the crypto")
    args = parser.parse_args()

    client = get_els_client()

    ### Put these in an enum ###
    # 4 tickers: BTC, ETH, DOGE, SOL
    load_dotenv()
    api_key = os.environ['CRYPTO_PANIC_KEY']
    url = f"https://cryptopanic.com/api/v1/posts/?auth_token={api_key}"
    # Query param static settings
    qp1 = "&public=true"
    # filter=(rising|hot|bullish|bearish|important|saved|lol): -> no need. btw, bullish votes: good bearish votes: bad
    qp2 = f"&currencies={args.ticker}"
    qp3 = "&approved=true"
    
    page = 1
    while True:
        qp4 = f"&page={page}"

        # use ayncio + requests? (for each pages)
        # in that case, there are 10 pages for each ticker
        # hence = 10 x 4 = 40 requests and that's not feasible.. cuz of the rate limit
        # Assuming this is used as in a DAG, execute tasks dynamically each with their own tickers,
        # sequentially execute each page with a time.sleep gapping within each task.
        resp = requests.get(url + qp1 + qp2 + qp3 + qp4)
        data = resp.json()

        ### Dupe check issue['id'] for dupe when ingesting ###
        # For each page, there are issues in data['results'] as a list.
        for issue in data['results']:
            # Each can either be a news or a media(e.g. YT) and has ids and urls.
            # issue['source']['url'] -> original article handled by the next stage? i.e., logstash?
            client.index(index="news_doc", id=issue['id'], document=issue)
        if data['next'] is None:
            break
        page += 1

        time.sleep(2)
    
    client.close()