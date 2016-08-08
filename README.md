# Flick API

## Motivation
At home we use Flick Electric as our power company. Unlike most electricity resellers in New Zealand, they bill you at the current spot price. Usually this is very good; overnight you can pay just cents per kilowatt hour. However at during peak times the price may be 3 or 4 times the usual price.

The Flick mobile app is able to report the current realtime price to you, so obviously there is an API involved somewhere. Some quick snooping with mitmproxy soon revealed that there was a nicely thought out web API just waiting for me to talk to.

Using the API, I am able to query the current market rate and act accordingly. For example:
* By multiplying the current spot price by my current power consumption, I can measure my power usage in "dollar-hours"; i.e. how many dollars it would cost me if I kept consuming power at the current rate.
* By cross referencing with a thermometer, then during Winter I can turn my heatpump on once the night time price kicks in, and turn it off again as soon as the morning power usage spikes. (11PM till 6AM).

## API
The API is pretty basic at the moment. Just create an instance of the class, passing in your Flick username and password, and then set up handlers for the events. Then you can start querying the price. It caches the authentication data.

## Events
This is an event based API.

* `authenticated` – emitted once the bearer token has been acquired. No parameters.
* `error` – emitted on any type of error. Argument is the error string.
* `price` – emitted once the price is known. Result is in dollars.
* `commentary` – emitted along with the price, this is the slogan that Flick sends along with the price. E.g. "Your price right now is limbo low."

## Example
```javascript
var FlickAPI = require('flick-electric-api')

// set up API
var flick = new FlickAPI('username', 'password');

// attach some events
flick.on('error', function(err) { console.log("Error: " + err); });
flick.on('price', function(price) { console.log("Current price: $" + price + "per kWhr") });

// and get the current price
flick.get_price();
```

## Low Level API Details
Communication with the Flick API is through a web service. Authentication is via JWT.

### Getting a bearer token
This is the first step of communicating with the API. We need to convert your username and password into a bearer token.

#### Request
Example POST request to `https://api.flick.energy/identity/oauth/token`, as recorded by mitmproxy.

```
Content-Type:     application/x-www-form-urlencoded
User-Agent:       Dalvik/2.1.0 (Linux; U; Android 6.0.1; Galaxy Nexus Build/MMB29U)
Host:             api.flick.energy

URLEncoded form
grant_type:     password
client_id:      le37iwi3qctbduh39fvnpevt1m2uuvz
client_secret:  ignwy9ztnst3azswww66y9vd9zt6qnt
username:       <username>
password:       <secret>
```

#### Response
```
{
    "access_token": "...",
    "expires_in": 5184000,
    "id_token": "<1>.<2>.<3>",
    "token_type": "bearer"
}
```

The only part we are interested in here is the `id_token` field.

### Getting market price
Once you have a bearer token, you can make a GET request to `https://api.flick.energy/customer/mobile_provider/price`, passing in your bearer token in the authentication header.

#### Request
```
Host:              api.flick.energy
User-Agent:        Mozilla/5.0 (Linux; Android 6.0.1; Galaxy Nexus Build/MMB29U; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/50.0.2661.86 Mobile Safari/537.36
Authorization:     Bearer <1>.<2>.<3>
```

#### Result
```
{"kind":"mobile_provider_price","customer_state":"active","needle":{"position":2,"commentary":"Your price right now is limbo low.","price":18.037}}
```

The resulting price is in cents, but we convert into dollars internally, because honestly, who uses cents.
