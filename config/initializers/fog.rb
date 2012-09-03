config = YAML::load(File.open("#{Rails.root}/config/fog.yml"))[Rails.env]
Fog.mock!
$fog = Fog::Compute.new(
  :provider               => config['provider'],
  :region                 => config['region'],
  :aws_access_key_id      => config['aws_access_key_id'],
  :aws_secret_access_key  => config['aws_secret_access_key']
)
$slave_image_ids = {
  :ap_southeast_1 => config['ap_southeast_1']
}