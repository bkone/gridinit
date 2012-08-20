class ArticlesController < ApplicationController
  def show
    html = RedCloth.new(open("#{Rails.root}/public/docs/#{params[:id]}.textile") {|f| f.read }).to_html
    respond_to do |format|
      format.html { render :inline => html }
    end
  end

end