#==============================================================================
# ** Tweet
#-----------------------------------------------------------------------------
# An abstract representation of a scheduled tweet message.
#==============================================================================

class Tweet

  attr_reader   :type
  attr_reader   :message

  def initialize(time, type, message)
    @time = time
    @type = type
    @message = message
  end

  def ready?
    return Time.at(@time) == Time.at(Time.now)
  end

end
