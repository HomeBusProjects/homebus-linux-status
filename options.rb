require 'homebus/options'

class LinuxHomebusAppOptions < Homebus::Options
  def app_options(op)
  end

  def banner
    'HomeBus Linux system status publisher'
  end

  def version
    '0.0.1'
  end

  def name
    'homebus-linux'
  end
end
