#!/bin/env ruby
# encoding: utf-8

require_relative "../tweet"

#==============================================================================
# ** Choose
#==============================================================================

module Choose

  Choose_Text = "@%s I really recommend choosing %s."

end

#==============================================================================
# Alice chooses an option for you.
#==============================================================================

class Dekkai

  #----------------------------------------------------------------------------
  # * Mention Handling
  #----------------------------------------------------------------------------

  alias update_choose_mention update_mention
  def update_mention(mention)
    update_choose_mention(mention)
    return if @replied_to_mention
    backref = mention.text.match(/!choose\s(.+)\Z/i)
    return if not backref
    choices = (backref[1].gsub(/,([^\s])/) { ", #{$1}" }).split(", ")
    reply = sprintf(Choose::Choose_Text, mention.user.screen_name,
        choices.sample)
    tweet = Tweet.new(Time.now + 1, :standard, reply)
    reply_to_mention(mention, tweet)
  end

end
