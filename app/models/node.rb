class Node < ActiveRecord::Base
	after_initialize :init

    def init
      self.user_id  ||= 0
    end
end