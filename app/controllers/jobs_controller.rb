class JobsController < ApplicationController
  before_filter :require_site_admin
  POPULAR_TAG_COUNTS = 10
  LIMIT = 100

  def index
    if params[:id].present?
      params[:q] = params[:id]
      params[:flavor] = 'all'
    end

    jobs_scope

    respond_to do |format|
      format.html do
        running
        tags(@jobs)
        @jobs_count = @jobs.count
      end

      format.js do
        result = {}
        case params[:only]
        when 'running'
          result[:running] = running
        when 'tags'
          result[:tags] = tags(@jobs)
        when 'jobs'
          result[:jobs] = @jobs.all(
            :limit => params[:limit] || LIMIT,
            :offset => params[:offset].try(:to_i))
          result[:total] = @jobs.count
        end
        render :json => result.to_json(:include_root => false)
      end
    end
  end

  def batch_update
    jobs_scope

    case params[:update_action]
    when 'hold'
      @jobs.find_each { |job| job.hold! }
    when 'unhold'
      @jobs.find_each { |job| job.unhold! }
    when 'destroy'
      @jobs.find_each { |job| job.destroy }
    end

    render :json => { :status => 'OK' }
  end

  protected

  def running
    @running = Delayed::Job.running.scoped(:order => 'id desc')
  end

  def tags(scope)
    @tags = scope.count(:group => 'tag', :limit => POPULAR_TAG_COUNTS, :order => 'count(tag) desc', :select => 'tag').map { |t,c| { :tag => t, :count => c } }
  end

  def jobs_scope
    @flavor = params[:flavor] || 'current'

    case @flavor
    when 'future'
      @jobs = Delayed::Job.future
    when 'current'
      @jobs = Delayed::Job.current
    when 'all'
      # pass
      @jobs = Delayed::Job
    when 'failed'
      @jobs = Delayed::Job::Failed
    end

    @jobs = @jobs.scoped(:order => 'id desc')

    if params[:q].present?
      @jobs = @jobs.scoped(:conditions => ["#{ActiveRecord::Base.wildcard('tag', params[:q])} OR id = ?", params[:q].to_i])
    end

    if params[:job_ids].present?
      @jobs = @jobs.scoped(:conditions => { :id => params[:job_ids].map(&:to_i) })
    end
  end

end
