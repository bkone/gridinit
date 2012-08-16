class PagesController < ApplicationController
  def home
  	@total_threads = Run.sum(:threads)
  end
end
