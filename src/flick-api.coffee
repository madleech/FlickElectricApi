request = require 'superagent'
{EventEmitter} = require 'events'

class FlickAPI extends EventEmitter
	constructor: (@username, @password) ->
		@get_token()
	
	get_token: ->
		request
			.post 'https://api.flick.energy/identity/oauth/token'
			.type 'form'
			.send {
				grant_type:    'password'
				client_id:     'le37iwi3qctbduh39fvnpevt1m2uuvz'
				client_secret: 'ignwy9ztnst3azswww66y9vd9zt6qnt'
				username:       @username
				password:       @password
			}
			.end (err, resp) =>
				if err
					@emit 'error', err.response?.text || "Error", err
				else if resp.body.id_token
					@token = resp.body.id_token
					@emit 'authenticated'
				else
					@emit 'error', "Invalid response", resp.text
	
	get_price: ->
		unless @token
			@get_token()
			return @once 'authenticated', => @get_price()
		
		request
			.get 'https://api.flick.energy/customer/mobile_provider/price'
			.set 'Authorization', "Bearer #{@token}"
			.end (err, resp) =>
				# {"kind":"mobile_provider_price","customer_state":"active","needle":{"price":"20.049","status":"urn:flick:market:price:forecast","unit_code":"cents","per":"kwh","start_at":"2018-06-01T09:30:00Z","end_at":"2018-06-01T09:59:59Z","now":"2018-06-01T09:38:14.322Z","type":"rated","charge_methods":["kwh","spot_price"],"components":[{"charge_method":"kwh","value":"3.36"},{"charge_method":"kwh","value":"0.113"},{"charge_method":"kwh","value":"0.48"},{"charge_method":"kwh","value":"10.19"},{"charge_method":"spot_price","value":"5.906"}]}}
				if err
					@emit 'error', "Error", err
				else if resp.body.kind == 'mobile_provider_price'
					@emit 'price', resp.body.needle.price / 100
				else
					@emit 'error', "Invalid response", resp.text

module.exports = FlickAPI
