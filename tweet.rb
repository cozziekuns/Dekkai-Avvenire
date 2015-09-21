#==============================================================================
# ** Tweet
#-----------------------------------------------------------------------------
# An abstract representation of a scheduled tweet message.
#==============================================================================

class Tweet

  attr_reader   :type
  attr_reader   :message
  attr_accessor :sent

  def initialize(time, type, message)
    @time = time
    @type = type
    @message = message
    @sent = false
  end

  def ready?
    return Time.at(@time) - Time.at(Time.now) <= 0
  end

end
