IMGKit.configure do |config|
  config.wkhtmltoimage = ['a'].pack('P').length  > 4 ? '/var/wkhtmltopdf/wkhtmltoimage-amd64' : '/var/wkhtmltopdf/wkhtmltoimage-i386'
  config.wkhtmltoimage = '/usr/local/bin/wkhtmltoimage' if RUBY_PLATFORM =~ /darwin/
  config.default_options = {
    :quality => 60
  }
  config.default_format = :png
end