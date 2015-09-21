#!/bin/env ruby
# encoding: utf-8

require_relative "../tweet"

#===============================================================================
# Sends a handshake message to twitter.
#===============================================================================

module Shake
  
  Shake_Message = "でっかいオンラインです。"

end

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

  alias init_scripts_shake init_all_scripts
  def init_all_scripts
    init_scripts_shake
    init_shake
  end

  def init_shake
    tweet = Tweet.new(Time.now + 3, :standard, Shake::Shake_Message)
    @tweet_queue.push(tweet)
  end

end
