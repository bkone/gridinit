class Run < ActiveRecord::Base
  after_create :queue

  def queue
    params.delete :authenticity_token
    self.privacy_flag = 0
    if self.params[:nodes]
      self.params[:nodes].each do |node|
        self.status = 'queued'
        self.user_id = params[:user]
        Resque::Job.create(node, Run, self.id, self.params)
      end
      self.threads = self.params[:nodes] * self.params[:threads]
    else
      self.status = 'queued'
      self.user_id = params[:user]
      self.threads = self.params[:threads]
      Resque::Job.create(self.params[:node], Run, self.id, self.params)
    end
    save!
  end

  def self.perform(id, params)
    params = Hash[params.map{ |k, v| [k.to_sym, v] }]
    run = Run.find_by_id(id)
    `curl http://#{params[:master]}/runs/status/#{id}?status=running`
    execute(params)
    `curl http://#{params[:master]}/runs/status/#{id}?status=completed`
  end

  def self.execute(params)
    testplan = Tempfile.new('testplan')
    if params[:testplan]
      file = "http://#{params[:master]}/attachments/#{params[:testplan]}"
    else
      file = "#{Rails.root}/config/#{params[:source]}"
    end
    # testplan.write(open(file) { |f| f.read } )
    
    contents = File.open(file) { |f| f.read }
    contents.gsub!(/ThreadGroup.num_threads">.+?</, 'ThreadGroup.num_threads">50<')
    testplan.write(open(file) { |f| contents } )

    Dir['/var/log/gridnode-*'].map {|a| `cat /dev/null > /var/log/#{File.basename(a)}` }

    heap_size =  Rails.env.development? ? '512m' : '2048m'
    cmd = case params[:source]
    when 'watirwebdriver'
      "/usr/bin/ruby #{testplan.path} \
      #{params[:url]} \
      #{params[:testguid]} 1\
      >>/var/log/gridnode-watirwebdriver.log 2>&1"
    when 'jmeter'
      "java -server -XX:+HeapDumpOnOutOfMemoryError \
      -Xms#{heap_size} -Xmx#{heap_size} \
      -XX:NewSize=128m -XX:MaxNewSize=128m \
      -XX:MaxTenuringThreshold=2 \
      -Dsun.rmi.dgc.client.gcInterval=600000 \
      -Dsun.rmi.dgc.server.gcInterval=600000 \
      -XX:PermSize=64m -XX:MaxPermSize=128m \
      -jar /usr/share/jmeter/bin/ApacheJMeter.jar \
      -p #{Rails.root}/config/jmeter.properties \
      -n -t #{testplan.path} \
      -j /var/log/gridnode-stdout.log \
      -l /var/log/gridnode-jmeter.log \
      -Jthreads=#{params[:threads]} \
      -Jrampup=#{params[:rampup]} \
      -Jduration=#{params[:duration]} \
      -Jhost=#{params[:host]} \
      -Jpath=#{params[:path]} \
      -Jtestguid=#{params[:testguid]} \
      2>>/var/log/gridnode-stderr.log"
    end
    logger.debug cmd
    `#{cmd}`
    testplan.close
    testplan.unlink
  end
end