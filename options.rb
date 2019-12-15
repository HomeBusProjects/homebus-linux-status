require 'homebus_app_options'

class LinuxHomebusAppOptions < HomeBusAppOptions
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
