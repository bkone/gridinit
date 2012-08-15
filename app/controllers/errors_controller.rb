class ErrorsController < ApplicationController
  before_filter :require_admin!, :except => [:show]

  def show
    respond_to do |format|  
      format.json { render :json => send(params[:id]) }
      format.html { render :text => IO.readlines("#{Rails.root}/public/uploads/#{params[:id]}").join("\n") }
      format.png  { send_data(IMGKit.new(IO.readlines("#{Rails.root}/public/uploads/#{params[:id]}").join("\n")).to_img(:png), :type => "image/png", :disposition => 'inline')}
    end  
  end

  private

  def get_snapshots; Elasticsearch.get_snapshots(params) end

end