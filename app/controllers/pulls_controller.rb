class PullsController < ApplicationController
  unloadable
  
  #menu_item :pull_requests
  before_filter :find_project
  before_filter :find_repository, :only => [:new, :edit, :create, :update]

  def index
    @pulls = Pull.find(:all, :order => 'created_on DESC')
  end
  
  def show
    @pull = Pull.find(params[:id])
    @repository = @pull.repository
    @base_branch = @pull.base_branch
    @head_branch = @pull.head_branch
    show_diff(@repository, @base_branch, @head_branch)
  end

  def new
    @base_branch = params[:base_branch]
    @head_branch = params[:head_branch]

    @repositories = @project.repositories
    #@repos = @repositories.sort.collect {|repo| repo.name}

    # diff
    if @head_branch.present? and @base_branch.present?
      show_diff(@repository, @base_branch, @head_branch)
    end
  end

  def create
    @pull = @project.pulls.build(params[:pull])
    @pull.repository = @repository
    @pull.user = User.current
    if @pull.save
      flash[:notice] = l(:notice_pull_created)
      redirect_to :action => 'show', :project_id => @project.name, :id => @pull.id
    else
      render :new
    end
  end

  def edit
    @pull = Pull.find(params[:id])
    @repository = params[:repository_id].present? ? @repository : @pull.repository
    @base_branch = params[:base_branch].present? ? params[:base_branch] : @pull.base_branch
    @head_branch = params[:head_branch].present? ? params[:head_branch] : @pull.head_branch

    @repositories = @project.repositories
    #@repos = @repositories.sort.collect {|repo| repo.name}

    # diff
    if @head_branch.present? and @base_branch.present?
      show_diff(@repository, @base_branch, @head_branch)
    end    
  end
  
  def update
    @pull = Pull.find(params[:id])
    @pull.repository = @repository
    @pull.user = User.current
    if @pull.update_attributes(params[:pull])
      flash[:notice] = l(:notice_pull_updated)
      redirect_to :action => 'show', :project_id => @project.name, :id => @pull.id
    else
      render :edit
    end
  end
  
  def destroy
  end
  
  private

  def find_project
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_repository
    if params[:repository_id].present?
      @repository = @project.repositories.find_by_identifier_param(params[:repository_id])
    else
      @repository = @project.repository
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  
  def show_diff(repository, base_branch, head_branch)
      @path = ''
      @rev = base_branch
      @rev_to = head_branch

      @revisions = repository.revisions('', @rev, @rev_to)

      @diff_type = 'inline'
      @cache_key = "repositories/diff/#{@repository.id}/" +
                      Digest::MD5.hexdigest("#{@path}-#{@revisions}-#{@diff_type}-#{current_language}")
      unless read_fragment(@cache_key)
        @diff = []
        @revisions.each do |r|
          @diff.concat(@repository.diff(@path, r.scmid, nil))
        end
      end
  end
end