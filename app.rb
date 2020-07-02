# coding: utf-8
require 'homebus'
require 'homebus_app'
require 'mqtt'
require 'dotenv'
require 'net/http'
require 'json'

require 'vmstat'

class LinuxHomebusApp < HomeBusApp
  DDC = 'org.homebus.experimental.server-status'

  def initialize(options)
    @options = options
    super
  end

  def update_delay
    60
  end

  def setup!
    Dotenv.load('.env')
    @mount_points = (ENV['MOUNT_POINTS'] || '').split(/\s/)
  end

  def _get_memory
    result = Hash.new

    memory = File.read('/proc/meminfo')
    m = memory.match /MemTotal:\s+(\d+) kB/
    if m
      result[:total] = m[1].to_i
    end

    m = memory.match /MemFree:\s+(\d+) kB/
    if m
      result[:free] = m[1].to_i
    end

    m = memory.match /MemAvailable:\s+(\d+) kB/
    if m
      result[:available] = m[1].to_i
    end

    result
  end

  def _get_filesystem(mount_point)
    df = `df #{mount_point}`

    m = df.match /^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(\W+)/
    device = m[1]
    total_blocks = m[2].to_i
    available_blocks = m[3].to_i
    free_blocks = m[4].to_i
    used_percentage = m[5].to_i
    
    {
      mount_point: mount_point,
      device: device,
      total_blocks: total_blocks,
      available_blocks: available_blocks,
      free_blocks: free_blocks,
      used_percentage: used_percentage
    }
  end

  def _get_filesystems
    @mount_points.map do |mount|
      _get_filesystem mount
    end
  end

  def work!
    vmstat = Vmstat.snapshot


    payload  = {
      system: {
        uptime: (Time.now - vmstat.boot_time).to_i,
        version: File.read("/etc/issue.net").chomp!,
        kernel_version: `uname -r`.chomp!,
        hostname: File.read('/etc/hostname').chomp!
      },
      filesystems: _get_filesystems,
      load: {
        one_minute: vmstat.load_average.one_minute,
        five_minutes: vmstat.load_average.five_minutes,
        fifteen_minutes: vmstat.load_average.fifteen_minutes
      },
      memory: _get_memory
    }

    answer =  {
      source: @uuid,
      timestamp: Time.now.to_i
      contents: {
        ddc: DDC,
        payload: payload
      }
    }

    if @options[:verbose]
      pp answer
    end

    publish! DDC, answer

    sleep update_delay
  end

  def manufacturer
    'HomeBus'
  end

  def model
    'Linux system status'
  end

  def friendly_name
    'Linux system status'
  end

  def friendly_location
    'Portland, OR'
  end

  def serial_number
    File.read('/etc/hostname')
  end

  def pin
    ''
  end

  def devices
    [
      { friendly_name: 'Linux system status',
        friendly_location: 'Portland, OR',
        update_frequency: update_delay,
        index: 0,
        accuracy: 0,
        precision: 0,
        wo_topics: [ DDC ],
        ro_topics: [],
        rw_topics: []
      }
    ]
  end
end
