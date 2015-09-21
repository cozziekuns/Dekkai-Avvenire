#!/bin/env ruby
# encoding: utf-8

require "twitter"
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
  puts "Internal Error with Twitter's Server. Retrying in 600s..."
  sleep(600)
  retry
rescue Twitter::Error::RequestTimeout
  puts "Request Timeout. Retrying in 600s..."
  sleep(600)
  retry
rescue Twitter::Error::ServiceUnavailable
  puts "Twitter Service unavailable. Retrying in 600s..."
  sleep(600)
  retry
rescue Twitter::Error::Unauthorized
  puts "Bad authentication data (check secret.rb?)"
rescue Twitter::Error => e
  puts "Unknown Twitter Error."
  puts "Message: " + e.message
  puts "Backtrace: " + e.backtrace.join("\n")
  sleep(600)
  retry
rescue Interrupt
  puts "Connection to Dekkai was closed."
rescue Exception => e
  puts "Exception Class: " + e.class.to_s
  puts "Message: " + e.message
  puts "Backtrace: " + e.backtrace.join("\n")
ensure
  dekkai.exit_gracefully
end
