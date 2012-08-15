class AttachmentsController < ApplicationController
  def show
    @attachment = Attachment.find(params[:id])
    # send_data @attachment.data, :filename => @attachment.filename
    render :text => @attachment.data
  end

  def create      
    return if params[:attachment].blank?

    @attachment = Attachment.new
    @attachment.uploaded_file = params[:attachment]
  end
end