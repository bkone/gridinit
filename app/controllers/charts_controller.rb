class ChartsController < ApplicationController
  def show
    params[:interval] ||= 'second'
    render :json => send(params[:id])
  end

  private

  def get_response_times; Elasticsearch.get_response_times(params) end
  def get_response_times_by_label; Elasticsearch.get_response_times_by_label(params) end
  def get_errors_by_label; Elasticsearch.get_errors_by_label(params) end
  def get_throughput; Elasticsearch.get_throughput(params) end
  def get_concurrency; Elasticsearch.get_concurrency(params) end
  def get_response_codes; Elasticsearch.get_response_codes(params) end
  def get_total_hits; Elasticsearch.get_total_hits(params) end
end