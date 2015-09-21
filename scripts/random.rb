#!/bin/env ruby
# encoding: utf-8

require_relative "../tweet"
require_relative "../settings"

#===============================================================================
# ** Quotes
#===============================================================================

module Quotes

  Random_Message_File = "scripts/quotes.txt"

  Interval_Min = 2400
  Interval_Max = 7200
  Before_Repeats = 5

  Added_Quote_Text = "@%s でっかいロジャーです。"

end

#===============================================================================
# Sends out scheduled, random tweets at random intervals.
#===============================================================================

class Dekkai

  #---------------------------------------------------------------------------
  # * Initialisation
  #---------------------------------------------------------------------------

  alias init_scripts_random init_all_scripts
  def init_all_scripts
    init_scripts_random
    init_random_messages
    queue_random_tweet
  end

  def init_random_messages
    @last_messsages = []
    @random_messages = []
    read_all_quotes
  end

  #----------------------------------------------------------------------------
  # * Mention Handling
  #----------------------------------------------------------------------------

  alias update_quote_mention update_mention
  def update_mention(mention)
    update_quote_mention(mention)
    return if @replied_to_mention
    backref = mention.text.match(/Add\sQuote:\s?\"(.+)\"\Z/i)
    return if not backref or backref[1].strip.empty?
    add_quote(backref[1].strip)
    reply = sprintf(Quotes::Added_Quote_Text, mention.user.screen_name)
    tweet = Tweet.new(Time.now + 1, :standard, reply)
    reply_to_mention(mention, tweet)
  end

  #----------------------------------------------------------------------------
  # * Tweet Resolution
  #----------------------------------------------------------------------------

  alias resolve_tweet_random resolve_tweet
  def resolve_tweet(tweet)
    queue_random_tweet if tweet.type == :random_scheduled
    resolve_tweet_random(tweet)
  end

  #----------------------------------------------------------------------------
  # * Helper Methods
  #----------------------------------------------------------------------------

  def read_all_quotes
    File.open(Quotes::Random_Message_File, "r+") { |file|
      file.each_line { |line|
        quote = line.strip
        next if quote.empty?
        @random_messages.push(quote)
      }
    }
  end

  def add_quote(message)
    File.open(Quotes::Random_Message_File, "a+") { |file|
      file.write(message + "\n")
    }
    @random_messages.push(message)
  end

  def queue_random_tweet
    index = rand(@random_messages.size)
    while @last_messsages.size > 5 and @last_messsages.include?(index)
      index = rand(@random_messages.size)
    end
    message = @random_messages[index]
    increment = rand(Quotes::Interval_Max - Quotes::Interval_Min + 1)
    time = Time.now + Quotes::Interval_Min + increment
    tweet = Tweet.new(time, :random_scheduled, message)
    @tweet_queue.push(tweet)
    update_random_indicies(index)
  end

  def update_random_indicies(index)
    @last_messsages.unshift(index)
    @last_messsages.pop if @last_messsages.size > Quotes::Before_Repeats
  end

end
