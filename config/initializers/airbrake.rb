if Rails.env.production?
  Airbrake.configure do |config|
    config.api_key = '29890054-ccec-4a4d-aec1-2b8966d4bb0f'
    config.host = 'crashlog.io'
  end
end