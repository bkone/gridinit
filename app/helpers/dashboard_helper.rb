module DashboardHelper
  def ip(hostname)
    Socket.getaddrinfo(hostname, "http", nil, :STREAM)[0][2]
  end

  def is_port_open?(ip, port)
    begin
      Timeout::timeout(1) do
        begin
          s = TCPSocket.new(ip.chomp, port)
          s.close
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          return false
        end
      end
    rescue Timeout::Error
    end
    return false
  end

  def get_monit(host=nil)
    begin
      monit = Nokogiri::HTML(open("http://#{host}:2812/")).css('table:last-child > tr').to_s[/\d+\.\d+%us.+?wa/].split(',').collect {|x| x[/[\d\.]+/].to_f}.reduce(:+).round(1)
    rescue => e 
    end
    monit ||= '--'
  end

  def check_ports(node)
    ports = { :Logstash => 9292, :ElasticSearch => 9200, :ZMQ => 5672 }
    checked = {}
    if node.role =~ /master|standalone/
      checked[:Logstash] = is_port_open?(node.host, ports[:Logstash])
      checked[:ElasticSearch] = is_port_open?(node.host, ports[:ElasticSearch])
    else
      checked[:ZMQ] = is_port_open?(node.host, ports[:ZMQ])
    end
    passed = checked.count{|x| x[1]==true}
    return ports, checked, passed
  end

  def threads_limit
    if current_user
      case current_user.role
      when 'admin'
        1000
      when 'paid'
        500
      else
        50
      end
    else
      50
    end
  end

  def rampup_limit
    if current_user
      case current_user.role
      when 'admin'
        7200
      when 'paid'
        3600
      else
        60
      end
    else
      60
    end
  end

  def duration_limit
    if current_user
      case current_user.role
      when 'admin'
        7200
      when 'paid'
        3600
      else
        60
      end
    else
      60
    end
  end
end