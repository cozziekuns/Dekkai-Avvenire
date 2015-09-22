#!/bin/env ruby
# encoding: utf-8

#===============================================================================
# Follow back anyone who follows Dekkai
#===============================================================================

class Dekkai

  #----------------------------------------------------------------------------
  # * Stream Handlers
  #----------------------------------------------------------------------------

  alias parse_received_event_followers parse_received_event
  def parse_received_event(event)
    parse_received_event_followers(event)
    follow_user(event.source) if event.name == :follow
  end

end
