class RunsController < ApplicationController
  def index
    @runs   = Run.find(:all,
      :conditions => ["privacy_flag IN(0,?)",
      (user_signed_in? ? [0,current_user.id] : 0)])
    @runs_paginated = Kaminari.paginate_array(@runs.reverse).page(params[:runs_page]).per(10)
    @domains = @runs.collect{|r| hash_keys_to_sym r.params}.collect {|p| p[:domain]}
    respond_to do |format|
      format.html
      format.json { render :json => @domains.uniq.to_json }
    end
  end

  def show
    @run = Run.find_by_id!(params[:id])
    params = hash_keys_to_sym @run.params
    if is_run_public? @run
      respond_to do |format|
        format.html {
          redirect_to URI.escape "/dashboard?tags=#{params[:source]}&testguid=#{params[:testguid]}&domain=#{params[:domain]}"
        }
        format.xml { 
          @attachment = Attachment.find(params[:testplan])
          send_data @attachment.data, :filename => @attachment.filename, :type => "text/xml"
        }
      end    
    else
      redirect_to :back, :alert => 'Access to this test is denied.'
    end
  end
  
  def share
    @run = Run.find_by_id!(params[:id])
    run_id = params[:id]
    params = hash_keys_to_sym @run.params
    redirect_to URI.escape "http://gridin.it/#{run_id}"
  end

  def compare
    @run = Run.find_by_id!(params[:id])
    run_id = params[:id]
    params = hash_keys_to_sym @run.params
    respond_to do |format|
      format.html {
        redirect_to URI.escape "/shared?tags=#{params[:source]}&testguid=#{params[:testguid]}&domain=#{params[:domain]}&run_id=#{run_id}"
      }
    end    
  end

  def set_public
    @run = Run.find_by_id!(params[:id])
    if permissions_on? @run
      @run.update_attributes(:privacy_flag => 0)
      redirect_to :back, :notice => 'Test was made public. Anyone can view its results.'
    else
      redirect_to :back, :alert => 'Access to this test is denied.'
    end
  end

  def set_private
    @run = Run.find_by_id!(params[:id])
    if permissions_on? @run
      @run.update_attributes(:privacy_flag => (user_signed_in? ? current_user.id : 0))
      redirect_to :back, :notice => 'Test was made private. Only you can view its results.'
    else
      redirect_to :back, :alert => 'Access to this test is denied.'
    end 
  end

  def create
    if paying_user?
      params[:testplan] = save_attachment
      params[:user]     = (user_signed_in? ? current_user.id : 0)
      params[:testguid] = generate_guid
      params[:domain]   = get_domain
      params[:master]   = request.host_with_port
      notify_support(params)
      Run.create! :params => params
      redirect_to URI.escape "/dashboard?tags=#{params[:source]}&testguid=#{params[:testguid]}&domain=#{params[:domain]}"
    else
      redirect_to :back, :alert => 'Advanced test plans are reserved for paid accounts only.'
    end
  end

  def destroy
    @run = Run.find_by_id!(params[:id])
    params = hash_keys_to_sym @run.params
    if permissions_on? @run
      `rm -f /var/gridnode/shared/uploads/*#{params[:testguid]}*`
      Run.delete(@run.id)
      redirect_to :back, :notice => 'Test was successfully deleted.'
    else
      redirect_to :back, :alert => 'Access to this test is denied.'
    end    
  end

  def notes
    @run = Run.find_by_id!(params[:id])
    if permissions_on? @run
      @run.update_attributes(:notes => params[:notes])
      render :text => params[:notes]
    else
      render :nothing => true
    end
  end

  def retest
    @run = Run.find_by_id!(params[:id])
    params = hash_keys_to_sym @run.params
    if permissions_on? @run
      params[:testguid]   = generate_guid
      params[:user]       = (user_signed_in? ? current_user.id : 0)
      Run.create! :params => params
      redirect_to URI.escape "/dashboard?tags=#{params[:source]}&testguid=#{params[:testguid]}&domain=#{params[:domain]}"
    else
      redirect_to :back, :alert => 'Access to this test is denied.'
    end
  end

  def quickie
    uri = URI.parse(params[:url])
    uri = URI.parse("http://#{params[:url]}") if uri.scheme.nil?
    params[:threads]    ||= 50
    params[:rampup]     ||= 50
    params[:duration]   ||= 10
    params[:host]       = uri.host
    params[:path]       = uri.path
    params[:user]       = (user_signed_in? ? current_user.id : 0)
    params[:testguid]   = generate_guid
    params[:node]       = ENV['PUBLIC_IPV4']
    params[:domain]     = uri.host
    params[:master]     = request.host_with_port
    notify_support(params)
    Run.create! :params => params
    redirect_to URI.escape "/dashboard?tags=#{params[:source]}&testguid=#{params[:testguid]}&domain=#{params[:domain]}"
  end

  def abort_running_tests
    redirect_to :back
  end

  def delete_queued_tests
    Run.delete_all("status = 'queued' and user_id = #{(user_signed_in? ? current_user.id : 0)}")
    redirect_to :back, :notice => 'Your queued tests were successfully deleted.'
  end

  def delete_all_tests
    Run.delete_all("user_id = #{(user_signed_in? ? current_user.id : 0)}")
    redirect_to :back, :notice => 'Your tests were successfully deleted.'
  end

  def status
    run = Run.find_by_id!(params[:id])
    run.update_attributes(:started => Time.now) unless run.started
    run.update_attributes(:status => params[:status])
    run.update_attributes(:completed => Time.now) if params[:status] == 'completed'
    render :nothing => true
  end

  private

  def notify_support(params)
    SupportMailer.send_feedback({
      :from => 'no-reply@gridinit.com', 
      :subject => "Test executing for #{params[:domain]}"}).deliver if Rails.env.production?
  end

  def permissions_on?(run)
    return true if admin_user?
    (user_signed_in? ? current_user.id : 0) == run.user_id ? true : false
  end

  def is_run_public?(params)
    if params.privacy_flag == 0
      true
    elsif user_signed_in?
      params.privacy_flag == current_user.id ? true : false
    else
      false
    end
  end

  def save_attachment
    attachment = Attachment.new
    attachment.uploaded_file = params[:attachment]
    attachment.save
    params.delete :attachment
    attachment.id
  end

  def get_domain
    if params[:url]
      uri = URI.parse(params[:url])
      uri = URI.parse("http://#{params[:url]}") if uri.scheme.nil?
      uri.host
    elsif params[:host].size > 0
      params[:host]
    elsif parse_testplan('stringProp[name="HTTPSampler.domain"]')
      parse_testplan('stringProp[name="HTTPSampler.domain"]').first.text
    else
      'multiple domains'
    end
  end

  def parse_testplan(css)
    attachment = Attachment.find(params[:testplan])
    Nokogiri::XML(attachment.data).css(css)
  end
end