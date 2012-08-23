class Node < ActiveRecord::Base
	has_many   :transactions
	after_initialize :init

    def init
      self.user_id  ||= 0
    end
end