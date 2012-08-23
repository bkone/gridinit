module DashboardHelper
  def get_monit(host=nil)
    begin
      Timeout::timeout(0.5) do
        monit = Nokogiri::HTML(open("http://#{host}:2812/")).css('table:last-child > tr').to_s[/\d+\.\d+%us.+?wa/].split(',').collect {|x| x[/[\d\.]+/].to_f}.reduce(:+).round(1)
      end
    rescue => e 
    end
    monit ||= '--'
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