import json
import ssl
from flask import Flask, jsonify
import upstox_client
import websockets
from google.protobuf.json_format import MessageToDict
import asyncio
import MarketDataFeed_pb2 as pb

app = Flask(__name__)

# http://localhost:5000/get_accumulated_data
# http://localhost:5000/start_market_data_feed

# Initialize variables for WebSocket and access token
websocket = None
access_token = 'access_token'

data_accumulator = []

def get_market_data_feed_authorize(api_version, configuration):
    """Get authorization for market data feed."""
    api_instance = upstox_client.WebsocketApi(upstox_client.ApiClient(configuration))
    api_response = api_instance.get_market_data_feed_authorize(api_version)
    return api_response

def decode_protobuf(buffer):
    """Decode protobuf message."""
    feed_response = pb.FeedResponse()
    feed_response.ParseFromString(buffer)
    return feed_response

async def fetch_market_data():
    global websocket

    if websocket is None:
        try:
            # Create default SSL context
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE

            # Configure OAuth2 access token for authorization
            configuration = upstox_client.Configuration()
            api_version = '2.0'
            configuration.access_token = access_token

            # Get market data feed authorization
            response = get_market_data_feed_authorize(api_version, configuration)

            # Connect to the WebSocket with SSL context
            websocket = await websockets.connect(response.data.authorized_redirect_uri, ssl=ssl_context)
        except Exception as e:
            return {'error': str(e)}

    try:
        if websocket:
            # Data to be sent over the WebSocket
            data = {
                "guid": "someguid",
                "method": "sub",
                "data": {
                    "mode": "full",
                    "instrumentKeys": ["NSE_INDEX|Nifty Bank", "NSE_INDEX|Nifty 50"]
                }
            }

            # Convert data to binary and send over WebSocket
            binary_data = json.dumps(data).encode('utf-8')
            await websocket.send(binary_data)

            async def data_generator():
                while True:
                    message = await websocket.recv()
                    decoded_data = decode_protobuf(message)

                    # Convert the decoded data to a dictionary
                    data_dict = MessageToDict(decoded_data)

                    # Add the data to the accumulator
                    data_accumulator.append(data_dict)

            await data_generator()
        else:
            return {'error': 'WebSocket connection not established'}
    except Exception as e:
        print(str(e))

@app.route('/start_market_data_feed', methods=['POST'])
def start_market_data_feed():
    asyncio.run(fetch_market_data())
    return jsonify({'message': 'Market data feed started'})

@app.route('/stop_market_data_feed', methods=['POST'])
def stop_market_data_feed():
    global websocket
    if websocket:
        websocket.close()
        websocket = None
    return jsonify({'message': 'Market data feed stopped'})

@app.route('/get_accumulated_data', methods=['GET'])
def get_accumulated_data():
    # Copy the data accumulator and clear it
    accumulated_data = list(data_accumulator)
    data_accumulator.clear()
    start_market_data_feed()  # Restart the data feed
    return jsonify(accumulated_data)

if __name__ == '__main__':
    app.run(debug=True)
