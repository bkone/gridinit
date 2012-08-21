config = YAML::load(File.open("#{Rails.root}/config/fog.yml"))[Rails.env]
$fog = Fog::Compute.new(
  :provider               => config['provider'],
  :region                 => config['region'],
  :aws_access_key_id      => config['aws_access_key_id'],
  :aws_secret_access_key  => config['aws_secret_access_key']
)