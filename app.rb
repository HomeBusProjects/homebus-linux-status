# coding: utf-8
require 'homebus'
require 'dotenv'

require 'vmstat'

class LinuxHomebusApp < Homebus::App
  DDC = 'org.homebus.experimental.server-status'

  def initialize(options)
    @options = options
    super
  end

  def update_interval
    60
  end

  def setup!
    Dotenv.load('.env')
    @mount_points = (ENV['MOUNT_POINTS'] || '').split(/\s/)

    hostname = ENV['HOSTNAME'] || `hostname`.chomp
    @device = Homebus::Device.new name: "Linux system status for #{hostname}",
                                  manufacturer: 'Homebus',
                                  model: 'Linux system status publisher',
                                  serial_number: hostname
  end

  def _get_memory
    result = Hash.new

    memory = File.read('/proc/meminfo')
    m = memory.match /MemTotal:\s+(\d+) kB/
    if m
      result[:total] = m[1].to_i*1024
    end

    m = memory.match /MemFree:\s+(\d+) kB/
    if m
      result[:free] = m[1].to_i*1024
    end

    m = memory.match /MemAvailable:\s+(\d+) kB/
    if m
      result[:available] = m[1].to_i*1024
    end

    result[:in_bytes] = true

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
      total_bytes: total_blocks*1024,
      available_bytes: available_blocks*1024,
      free_bytes: free_blocks*1024,
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

    if @options[:verbose]
      pp payload
    end

    publish! DDC, payload

    sleep update_delay
  end

  def name
    'Homebus Linux system status'
  end

  def publishes
    [ DDC ]
  end

  def devices
    [ @device ]
  end
end
