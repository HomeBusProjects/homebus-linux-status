require 'homebus/options'

require 'homebus-linux-status/version'

class HomebusLinuxStatus::Options < Homebus::Options
  def app_options(op)
  end

  def banner
    'HomeBus Linux system status publisher'
  end

  def version
    HomebusLinuxStatus::VERSION
  end

  def name
    'homebus-linux-status'
  end
end
