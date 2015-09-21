#!/bin/env ruby
# encoding: utf-8

require_relative "settings"
require_relative "tweet"

#==============================================================================
# ** Dekkai
#-----------------------------------------------------------------------------
# The skeleton of the main bot. All the main functions of the bot are
# performed by this class.
#==============================================================================

class Dekkai

  #---------------------------------------------------------------------------
  # * Initialisation
  #---------------------------------------------------------------------------

  def initialize(rest_client, stream_client)
    @rest_client = rest_client
    @stream_client = stream_client
    @tweet_queue = []
    create_tweet_stream
    load_scripts
    init_all_scripts
  end

  # Delegate a thread for the timeline to be streamed concurrently
  def create_tweet_stream
    @stream = Thread.new {
      @stream_client.user { |twitter_object|
        case twitter_object
        when Twitter::Tweet
          parse_received_tweet(twitter_object)
        when Twitter::Streaming::Event
          parse_received_event(twitter_object)
        else
          parse_received_object(twitter_object)
        end
      }
    }
  end

  def load_scripts
    Settings::Enabled_Scripts.each { |script|
      require_relative "scripts/#{script}"
    }
  end

  def init_all_scripts
  end

  #----------------------------------------------------------------------------
  # * Main loop
  #----------------------------------------------------------------------------

  def update
    send_scheduled_tweets
    update_all_scripts
    sleep(1)
  end
  
  def update_all_scripts
  end

  #----------------------------------------------------------------------------
  # * Stream Handlers
  #----------------------------------------------------------------------------

  def parse_received_tweet(tweet)
    if tweet.text.split(" ").any? { |s| 
      s == "@#{@rest_client.user.screen_name}" 
    }
      update_mention(tweet)
    end
  end

  def parse_received_event(event)
  end

  # To give scripts an endpoint for unknown objects that are received
  def parse_received_object(twitter_object)
  end

  #----------------------------------------------------------------------------
  # * API Calls
  #----------------------------------------------------------------------------

  def send_tweet(tweet, options={})
    begin
      @rest_client.update!(tweet.message, options)
      puts "Sent Tweet: #{tweet.message}"
    rescue Twitter::Error::DuplicateStatus
      puts "Error: Status was a duplicate. Removing from tweet queue."
    end
    resolve_tweet(tweet)
  end

  def reply_to_mention(mention, reply)
    send_tweet(reply, {:in_reply_to_status => mention})
    @replied_to_metion = true
  end

  def follow_user(user)
    begin
      @rest_client.follow([follower])
      puts "Follow request sent to: #{follower.screen_name}"
    rescue Twitter::Error::Forbidden
      puts "Follow request already sent to #{follower}."
    end
  end

  #----------------------------------------------------------------------------
  # * Mention Handling
  #----------------------------------------------------------------------------

  def update_mention(tweet)
    @replied_to_mention = false
  end

  def filter_links(text)
    text.gsub!(/http.+?(?:\s|\Z)/, "")
    text.gsub!(/pic\.tw.+?(?:\s|\Z)/, "")
    return text
  end

  def strip_mentions(text)
     return text.encode("utf-8", "utf-8").gsub(/@\w+/u, "")
  end

  #----------------------------------------------------------------------------
  # * Tweet Resolution
  #----------------------------------------------------------------------------

  def resolve_tweet(tweet)
    tweet.sent = true
  end

  #----------------------------------------------------------------------------
  # * Helper Methods
  #----------------------------------------------------------------------------

  def send_scheduled_tweets	  
    @tweet_queue.each { |tweet| send_tweet(tweet) if tweet.ready? }
    @tweet_queue.reject! { |tweet| tweet.sent }
  end

  #----------------------------------------------------------------------------
  # * Exit Routine
  #----------------------------------------------------------------------------

  def exit_gracefully
    @stream.kill
  end

end
