#!/usr/bin/env ruby

require './options'
require './app'

linux_app_options = LinuxHomebusAppOptions.new

linux = LinuxHomebusApp.new linux_app_options.options
linux.run!
