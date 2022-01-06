# import it
import requests
from requests import Request, Session
from requests.exceptions import ConnectionError, Timeout, TooManyRedirects
import json
import time
from datetime import datetime


# cmc_api_key = 'cce6753d-0e75-4a8e-aaae-1970ed16222b'
# endpoint = '/v1/cryptocurrency/ohlcv/latest'

# SETUP - API PARAMETERS/URL
btc_url = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest'
parameters = {
  'symbol':'BTC',
}
headers = {
  'Accepts': 'application/json',
  'X-CMC_PRO_API_KEY': 'cce6753d-0e75-4a8e-aaae-1970ed16222b',
}

ifttt_webhook_url = 'https://maker.ifttt.com/trigger/{}/with/key/cqy_djt8Z9zrvgC1SMKR0M'

# FUNCTION TO CALL BTC API FOR LATEST PRICE

def get_latest_bitcoin_price():
    response = requests.get(btc_url, params=parameters, headers=headers)
    data = response.json()
    btc_data = data['data']['BTC']['quote']['USD']
    btc_price=btc_data['price']
    return float(btc_price)

# FUNCTION TO POST REQUEST TO IFTTT

def post_ifttt_webhook(event, value):
    # --> The payload that will be sent to IFTTT service
    data = {'value1': value}
    # inserts our desired event
    ifttt_event_url = ifttt_webhook_url.format(event)
    # Sends a HTTP POST request to the webhook URL
    requests.post(ifttt_event_url, json=data)

# FUNCTION TO FORMAT THE BITCOIN PRICE HISTORY FOR IFTT
def format_bitcoin_history(bitcoin_history):
    rows = []
    for bitcoin_price in bitcoin_history:
        # Formats the date into a string: '24.02.2018 15:09'
        date = bitcoin_price['date'].strftime('%d.%m.%Y %H:%M')
        price = bitcoin_price['price']
        # <b> (bold) tag creates bolded text
        # 24.02.2018 15:09: $<b>10123.4</b>
        row = '{}: $<b>{}</b>'.format(date, price)
        rows.append(row)

    # Use a <br> (break) tag to create a new line
    # Join the rows delimited by <br> tag: row1<br>row2<br>row3
    return '<br>'.join(rows)


BITCOIN_PRICE_THRESHOLD = 60000
# RUN MAIN APP
def main():
    bitcoin_history = []
    while True:
        price = get_latest_bitcoin_price()
        date = datetime.now()
        bitcoin_history.append({'date': date, 'price': price})

        # Send an emergency notification
        if price < BITCOIN_PRICE_THRESHOLD:
            post_ifttt_webhook('bitcoin_price_emergency', price)

        # Send a Telegram notification
        # Once we have 5 items in our bitcoin_history send an update
        # NOTE - CANCELLED PRICE UPDATES FOR NOW
        if len(bitcoin_history) == 5:
            post_ifttt_webhook('bitcoin_price_update',
format_bitcoin_history(bitcoin_history))
            # Reset the history
            bitcoin_history = []

        # Sleep for 5 minutes
        # (For testing purposes you can set it to a lower number)
        time.sleep(15 * 60)


if __name__ == '__main__':
    main()


