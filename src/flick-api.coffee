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
					@emit 'error', "Error", err
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
				# {"kind":"mobile_provider_price","customer_state":"active","needle":{"position":2,"commentary":"Your price right now is limbo low.","price":18.037}}
				if err
					@emit 'error', "Error", err
				else if resp.body.kind == 'mobile_provider_price'
					@emit 'price', resp.body.needle.price / 100
					@emit 'commentary', resp.body.needle.commentary
				else
					@emit 'error', "Invalid response", resp.text

module.exports = FlickAPI
