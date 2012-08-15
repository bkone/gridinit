class SearchesController < ApplicationController
  respond_to :json

  def index
    # curl -XGET http://localhost:3000/_search?pretty=true -d '{"query":{"bool":{"must":[{"wildcard":{"testguid":"9cdac3a4e2b911e195770050569a066c*"}}]}}}'
    # curl -XGET http://localhost:3000/_search?pretty=true -d '{"query":{"match_all":{}}}'
    # http://127.0.0.1:3000/_search.json?q=testguid:9cdac3a4e2b911e19577005069a066c
    testguid = params[:q] ? params.to_s.index(/testguid:[\w\d]{31}/) : request.raw_post.index(/testguid":"[\w\d]{31}/)
    cmd = params[:q] ? "curl -X#{request.method} http://localhost:9200/_all/_search?#{params[:q]}" : 
      "curl -X#{request.method} http://localhost:9200/_all/_search?pretty=true -d '#{request.raw_post}'"
    logger.debug cmd
    if testguid
      respond_with(`#{cmd}`)
    else
      head :bad_request
    end
  end

end
