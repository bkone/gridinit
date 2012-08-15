class LogsController < ApplicationController
  def show
    params[:scroll_id] ||= 0   
    render :json => send(params[:id])
  end

  private

  def get_labels; Elasticsearch.get_labels(params) end
  def get_error_logs; Elasticsearch.get_error_logs(params) end
  def get_logs_by_message; Elasticsearch.get_logs_by_message(params) end
end