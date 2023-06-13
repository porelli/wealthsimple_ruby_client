require_relative 'lib/wealthsimple_ruby_client'
# require 'dotenv/load' # use this if you have stored variables in a local .env file

a = WealthSimpleClient.new(otp: '123456', username: ENV['user'], password: ENV['pass']) #, access_token: ENV['access_token'])
a.generate_export