class Elasticsearch

  def self.get_response_times(params)
    series = []
    series << get_series(params, 'time')
    series
  end

  def self.get_response_times_by_label(params)
    series = []
    labels(params).each_with_index do |label, index|
      params[:label] = label
      params[:colour_index] = index
      series << get_series(params, 'time')
    end
    series
  end

  def self.get_errors_by_label(params)
    series = []
    params[:successful] = false
    labels(params).each_with_index do |label, index|
      params[:label] = label
      params[:colour_index] = index
      series << get_series(params, 'error_count')
    end
    series
  end

  def self.get_throughput(params)
    params[:name]   = "Bytes Throughput"
    series          = []
    series << get_series(params, 'bytes')
    series
  end

  def self.get_concurrency(params)
    series = []
    hosts(params).each_with_index do |host, index|
      params[:host]           = host
      params[:name]           = host
      params[:colour_index]   = index
      series << get_series(params, 'active_threads')
    end
    series
  end

  def self.get_response_codes(params)
    series = []
    response_codes(params).each_with_index do |response_code, index|
      params[:response_code]  = response_code
      params[:name]           = response_code
      params[:colour_index]   = index
      series << get_series(params, 'response_code')
    end
    series
  end

  def self.get_total_hits(params)
    if params[:testguid]
      begin
        search = Tire.search '*' do
          query { string "testguid:#{params[:testguid]}" }
        end
        search.response.code == 200 ? search.results.total : 0
      rescue
        0
      end  
    else
      0
    end
  end

  def self.get_error_logs(params)
    search = Tire.search '*' do
      from params[:scroll_id].to_s
      fields ["@message", "@source_host"]
      size 50
      sort do
        by :timestamp, 'desc'
      end
      query do
        boolean do
          must { string "@message:#{params[:success]}*" }
          must { string "@message:#{params[:testguid]}*" }
          must { string "@type:errors" } 
        end
      end
    end
    search.results
  end

  def self.get_logs_by_message(params)
    search = Tire.search '*' do
      from params[:scroll_id].to_s
      fields ["@message"]
      size 50
      sort do
        by :timestamp, 'desc'
      end
      query do
        boolean do
          must { string "testguid:#{params[:testguid]}*" }
          must { string "@message:#{params[:filter]}*"  }
          must { string "@type:jmeter" } 
        end
      end
    end
    search.results
  end

  def self.get_snapshots(params)
    search = Tire.search '*' do
      fields ["@timestamp","@message", "@source_host"]
      size 50
      query do
        boolean do
          must { string "@message:*snapshot*" }
          must { string "@message:*#{params[:testguid]}*" }
          must { string "@type:stderr" } 
        end
      end
    end
    errors = []
    search.results.each do |item|
      error = "errors/#{item['@message'].split(': ')[2]}"
      host = Rails.env.development? ? "/" : "http://#{item["@source_host"]}/"
      errors << { 
        :timestamp => Time.parse(item["@timestamp"]).to_i, 
        :message => "<a href='#{host}#{error}.html'><img class='snapshot' src='#' data-png='#{host}#{error}.png'></a>"
      } 
    end
    errors.to_json
  end

  def self.get_labels(params)
    labels(params)
  end

  private

  def self.get_interval(params)
    case get_range(params)
    when 0..600
      'second'
    when 601..7200
      'minute'
    else
      'hour'
    end
  end

  def self.get_range(params)
    search = Tire.search '*' do
      query do
        boolean do
          must { string "testguid:#{params[:testguid]}*" }
          must { string "label:#{params[:label]}*" }
          must { string "@tags:#{params[:tags]}*"  }
        end
      end
      facet('stats') { statistical :timestamp }
    end
    (search.results.facets['stats']['max'] - search.results.facets['stats']['min'])/1000
  end

  def self.get_series(params, value_field)
    params[:interval] ||= get_interval(params)
    search = Tire.search '*' do
      query do
        boolean do
          # must { string "testguid:#{params[:testguid]}*" }
          must { text :testguid, params[:testguid] }
          must { text :label, params[:label] } if params[:label].size > 0
          must { string "@tags:#{params[:tags]}*"  }
          must { range :error_count, { :gte => 1 } } if value_field == 'error_count'
          must { string "@source_host:#{params[:host]}*" } if value_field == 'active_threads'
          must { string "response_code:#{params[:response_code]}"  } if value_field == 'response_code'
        end
      end
      facet('chart') { date :timestamp, {:interval => params[:interval], :value_field => value_field } }
      facet('stats') { statistical value_field.to_sym }
      facet('successful') { terms 'successful', { :all_terms => false, :size => 2 } }
    end
    {
      :name   => (params[:name] ? params[:name] : params[:label]), 
      :alt    => search.results.first['@fields']['response_message'].first,
      :color  => (value_field != 'response_code' ? get_colour(params[:colour_index]) : get_response_code_colour(params[:name])),
      :data   => format_series_data(search.results.facets, value_field),
      :stats  => get_statistics(search.results.facets),
      :apdex  => (value_field == 'time' ? calculate_apdex(search.results.facets, params[:satisfied].to_i) : []),
      # :raw    => search.results,
      :query  => search.to_curl
      
    }
  end

  def self.format_series_data(results, value_field)
    data = []
    results['chart']['entries'].each do |entry|
      data << {
        :x => (entry['time']/1000).to_i,
        :y => (value_field =~ /response_code|error_count/ ? entry['count'] : entry['mean'])
      }
    end
    data
  end

  def self.labels(params)
    labels = []
    search = Tire.search '*' do
      query do
        boolean do
          must { string "testguid:#{params[:testguid]}*" }
          must { string "label:#{params[:label]}*" }
          must { string "@tags:#{params[:tags]}*"  }
          must { string "successful:false*" } if params[:successful] == false
        end
      end
      facet('labels') { terms 'label', { :all_terms => false, :size => 20 } }
    end
    search.results.facets['labels']['terms'].each do |term|
      label = term['term'].to_s 
      labels << label unless labels.include? label and term['count'] > 0
    end
    labels
  end

  def self.hosts(params)
    hosts = []
    search = Tire.search '*' do
      query do
        boolean do
          must { string "testguid:#{params[:testguid]}*" }
          must { string "label:#{params[:label]}*" }
          must { string "@tags:#{params[:tags]}*"  }
        end
      end
      facet('hosts') { terms '@source_host', { :all_terms => false, :size => 20 } }
    end
    search.results.facets['hosts']['terms'].each do |term|
      host = term['term'].to_s 
      hosts << host unless hosts.include? host and term['count'] > 0
    end
    hosts
  end

  def self.response_codes(params)
    response_codes = []
    search = Tire.search '*' do
      query do
        boolean do
          must { string "testguid:#{params[:testguid]}*" }
          must { string "label:#{params[:label]}*" }
          must { string "@tags:#{params[:tags]}*"  }
        end
      end
      facet('response_codes') { terms 'response_code', { :all_terms => false, :size => 20 } }
    end
    search.results.facets['response_codes']['terms'].each do |term|
      response_code = term['term'].to_s 
      response_codes << response_code unless response_codes.include? response_code and term['count'] > 0
    end
    response_codes
  end

  def self.get_statistics(results)
    range = results['chart']['entries'].last['time']/1000 - results['chart']['entries'].first['time']/1000
    results['stats']['tps']  = results['stats']['count'].to_f / (range > 0 ? range.to_f : 1.to_f)
    results['stats']['last'] = results['chart']['entries'].last['mean'].to_i
    if results['successful']
      results['stats']['passed'], results['stats']['failed'] = 0, 0
      results['successful']['terms'].each do |term|
        results['stats']['passed'] += term['count'] if term['term'] == "true"
        results['stats']['failed'] += term['count'] if term['term'] == "false"
      end
      results['stats']['fps']  = results['stats']['failed'].to_f / (range > 0 ? range.to_f : 1.to_f)
    end
    results['stats']
  end

  def self.get_colour(colour_index)
    colour_index ||= 0
    %w[#2f243f #3c2c55 #4a3768 #565270 #6b6b7c #72957f #86ad6e 
       #a1bc5e #b8d954 #d3e04e #ccad2a #cc8412 #c1521d #ad3821 
       #8a1010 #681717 #531e1e #3d1818 #320a1b][colour_index % 18]
  end

  def self.get_response_code_colour(response_code)
    case response_code.to_i
    when 200..299
      'green'
    when 300.399
      'lightblue'
    when 400..499
      'steelblue'
    when 500..599
      'red'
    else
      '#FF0066'
    end
  end

  def self.get_apdex_colour(score)
    r=(255*((score/1)*100).to_i)/100
    g=(255*(100-((score/1)*100).to_i))/100
    b=0
    "rgba(#{g},#{r},#{b},0.1)"
  end

  def self.get_apdex_rating(score)
    case score
    when 0..0.49
      'unacceptable'
    when 0.5..0.69
      'poor'
    when 0.70..0.84
      'fair'
    when 0.85..0.93
      'good'
    when 0.94..1.00
      'excellent'
    else
      'N/A'
    end
  end

  def self.calculate_apdex(results, satisfied)
    satisfied     ||= 4000
    tolerated     = satisfied*2
    s, t, n       = 0, 0, 0
    results['chart']['entries'].each do |entry|
      s += 1 if (1..satisfied).member?(entry['mean'].to_i)
      t += 1 if (satisfied+1..tolerated).member?(entry['mean'].to_i)
      n += 1
    end
    score = ((s.to_f+(t.to_f/2))/n.to_f ).to_f 
    {
      :score      => score.round(2),
      :rating     => get_apdex_rating(score),
      :satisfied  => satisfied,
      :colour     => get_apdex_colour(score),
      :print      => "#{'%.2f' % score.round(2)}#{'*' if n < 100}[#{(satisfied/1000).to_i}]",
      :stat       => "#{'%.2f' % score.round(2)}<sup>#{'*' if n < 100}[#{(satisfied/1000).to_i}]</sup>"
    }
  end
end