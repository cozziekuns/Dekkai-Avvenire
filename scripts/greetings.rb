#!/bin/env ruby
# encoding: utf-8

require_relative "../tweet"

#===============================================================================
# ** Greetings
#===============================================================================

module Greetings

  Greeting_Messages_EN =[
    "@%s Really good morning, %s!",
    "@%s Morning, %s! Let's really do our best again today!",
    "@%s Morning, %s!",
  ]

  Greeting_Messages_JP =[
    "@%s %s先輩おはようございます！",
    "@%s %s先輩でっかいおはようございます！",
    "@%ss %sさん、おはよう！今日もでっかいがんばりましょう！",
  ]

  Farewell_Messages_EN =[
    "@%s Really good night, %s!",
    "@%s Good night, %s!",
    "@%s Night, %s!",
  ]

  Farewell_Messages_JP =[
    "@%s %sさん、おやすみなさい!",
    "@%s %sさん、おやす～",
    "@%s %s先輩でっかいおやすみなさい！",
  ]

  Greeting_Messages ={
    ["good morning", "hello", "morning"] => Greeting_Messages_EN,
    ["おはよう", "おはあ"] => Greeting_Messages_JP,
    ["good night"] => Farewell_Messages_EN,
    ["おやす"] => Farewell_Messages_JP,
  }

end

#===============================================================================
# Replies to various greetings and farewells.
#===============================================================================

class Dekkai

  #----------------------------------------------------------------------------
  # * Mention Handling
  #----------------------------------------------------------------------------

  alias update_greeting_mention update_mention
  def update_mention(mention)
    update_greeting_mention(mention)
    return if @replied_to_mention
    message = mention.text.downcase
    Greetings::Greeting_Messages.keys.each { |key|
      next if not key.find { |substring| message[substring] }
      reply_text = Greetings::Greeting_Messages[key].sample,
      reply = sprintf(reply_text, mention.user.screen_name, mention.user.name)
      tweet = Tweet.new(Time.now + 1, :standard, reply)
      reply_to_mention(mention, tweet)
      break
    }
  end

end
