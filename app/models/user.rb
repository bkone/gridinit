class User < ActiveRecord::Base
  attr_protected :provider, :uid, :name, :email, :avatar_url, :role

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      if auth['info']
        user.name = auth['info']['name'] || ""
        user.email = auth['info']['email'] || ""
      end
      if auth['provider'] == 'github'
        user.avatar_url = auth['extra']['raw_info']['avatar_url'][/avatar\/.+?\?/] || ""
      end
    end
  end
end
