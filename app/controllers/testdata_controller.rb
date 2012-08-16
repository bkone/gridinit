class TestdataController < ApplicationController
  def index
    @keys = Resque.redis.keys('*').delete_if {|x| x =~ /resque/ || x.size == 0 }
    @keys.each_with_index {|key, index| @keys[index] = "#{key}:#{Resque.redis.smembers(key).size}" }
    @keys_paginated = Kaminari.paginate_array(@keys.reverse).page(params[:keys_page]).per(10)
    respond_to do |format|
      format.html 
      format.json { render :json => @keys  }
    end
  end

  def show
    @key = params[:id]
    @members_paginated = Kaminari.paginate_array(Resque.redis.smembers(@key)).page(params[:members_page]).per(10)
    csv_string = Resque.redis.smembers(@key).join("\n")  

    respond_to do |format|
      format.html
      format.csv { send_data(csv_string, :filename => "#{@key}.csv", :type => "text/csv") }
    end
  end

  def create
    @key = params[:key].gsub(/[^0-9a-z]/i, '_')
    CSV.parse(params[:file].read) do |value| 
      Resque.redis.sadd(@key, value.to_json)
    end
    @members = Resque.redis.smembers(@key)
    redirect_to "/testdata/#{@key}"
  end

  def destroy
    if params[:command] == 'flushall'
      Resque.redis.flushall
      redirect_to :back
    elsif params[:command] == 'del'
      Resque.redis.del params[:id]
      redirect_to :back
    else
      Resque.redis.srem(params[:id], params[:member])
      redirect_to :back
    end
  end
end