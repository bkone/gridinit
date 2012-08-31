module DashboardHelper
  def get_monit(host=nil)
    begin
      Timeout::timeout(1) do
        monit = Nokogiri::HTML(open("http://#{host}:2812/")).css('table:last-child > tr').to_s[/\d+\.\d+%us.+?wa/].split(',').collect {|x| x[/[\d\.]+/].to_f}.reduce(:+).round(1)
      end
    rescue => e 
    end
    monit ||= '--'
  end

  def get_flag(node)
    case node.region
    when "us-east-1"
      "icon_flag_us.png"
    when "us-west-1"
      "icon_flag_us.png"
    when "us-west-2"
      "icon_flag_us.png"
    when "eu-west-1"
      "icon_flag_eu.png"
    when "ap-southeast-1"
      "icon_flag_ap.png"
    when "ap-northeast-1"
      "icon_flag_jp.png"
    when "sa-east-1"
      "icon_flag_br.png"
    when "au-nsw"
      "icon_flag_au.png"
    else
      "icon_flag_au.png"
    end
  end

  def threads_limit
    if paying_user? || admin_user?
      1000
    elsif current_user
      50
    else
      0
    end
  end

  def rampup_limit
    if paying_user? || admin_user?
      3600*3
    elsif current_user
      60
    else
      0
    end
  end

  def duration_limit
    if admin_user?
      3600*8
    elsif current_user
      60
    else
      0
    end
  end
end