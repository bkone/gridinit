ENV['PUBLIC_IPV4'] ||= `curl -s ifconfig.me`.chomp
ENV['PUBLIC_IPV4'] = '127.0.0.1' if Rails.env.development? || Rails.env.standalone?