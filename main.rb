#!/bin/env ruby
# encoding: utf-8

require "twitter"
require_relative "log"
require_relative "dekkai"
require_relative "secret"

#===============================================================================
# ** Main
#===============================================================================

Thread.abort_on_exception = true

rest_client = Twitter::REST::Client.new { |config|
  config.consumer_key = Secret::Consumer_Key
  config.consumer_secret = Secret::Consumer_Key_Secret
  config.access_token = Secret::Access_Token
  config.access_token_secret = Secret::Access_Token_Secret
}

stream_client = Twitter::Streaming::Client.new { |config|
  config.consumer_key = Secret::Consumer_Key
  config.consumer_secret = Secret::Consumer_Key_Secret
  config.access_token = Secret::Access_Token
  config.access_token_secret = Secret::Access_Token_Secret
}

# Run Dekkai on that client
dekkai = Dekkai.new(rest_client, stream_client)

begin
  loop { dekkai.update }
rescue Twitter::Error::InternalServerError
  Log.write("Internal Error with Twitter's Server. Retrying in 600s...")
  sleep(600)
  retry
rescue Twitter::Error::RequestTimeout
  Log.write("Request Timeout. Retrying in 600s...")
  sleep(600)
  retry
rescue Twitter::Error::ServiceUnavailable
  Log.write("Twitter Service unavailable. Retrying in 600s...")
  sleep(600)
  retry
rescue Twitter::Error::Unauthorized
  Log.write("Bad authentication data (check secret.rb?)")
rescue Twitter::Error => e
  Log.write("Unknown Twitter Error.")
  Log.write("Message: " + e.message)
  sleep(600)
  retry
rescue Interrupt
  Log.write("Connection to Dekkai was closed.")
rescue Exception => e
  Log.write("Exception Class: " + e.class.to_s)
  Log.write("Message: " + e.message)
  Log.write("Backtrace: " + e.backtrace.join("\n"))
ensure
  Log.close
  dekkai.exit_gracefully
end
