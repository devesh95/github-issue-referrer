class IssuesController < ApplicationController
  before_action :set_issue, only: [:show, :edit, :update, :destroy, :assign]

  # GET /issues
  # GET /issues.json
  def index
    load_suggestions
    @current_user = current_user
    @issues = []
    repos = github_client.repositories
    # magical API batch consoldiation
    repos.each do |repo|
      if repo.open_issues_count != 0
        issue_data = github_client.list_issues("#{repo.owner.login}/#{repo.name}")
        issue_data.each do |collect| 
          collect.repo = repo.name
        end
        @issues.push(issue_data)
      end
    end
  end

  # GET /issues/1
  # GET /issues/1.json
  def show
    @current_user = current_user
  end

  # GET /issues/new
  def new
    @issue = Issue.new
  end

  # GET /issues/1/edit
  def edit
  end

  # POST /issues
  # POST /issues.json
  def create
    @issue = Issue.new(issue_params)
    respond_to do |format|
      # create with a nil referrer in the table
      existing_issue = Issue.where(:id => @issue.id).first_or_create(issue_params) do |issue|
        # puts issue.inspect
        format.html { redirect_to issue, notice: 'Beginning the referral process. '}
        format.json { render :show, status: :created, location: issue }
      end
      format.html { redirect_to existing_issue, notice: 'Beginning the referral process. '}
      format.json { render :show, status: :created, location: existing_issue }
    end
  end

  # PATCH/PUT /issues/1
  # PATCH/PUT /issues/1.json
  def update
    # update referrer and notes (if any)
    data = get_form_data
    data['referrer'] = @issue.referrer ? ("#{@issue.referrer},#{data['referrer']}") : data['referrer']
    baseline_note = "<span class='label warning' style='margin-right: 5px'><strong>#{current_user.nickname}</strong></span>#{data['notes']}<br/>"
    data['notes'] = @issue.notes ? (@issue.notes + baseline_note) : baseline_note
    respond_to do |format|
      if @issue.update(data)
        format.html { redirect_to @issue, notice: 'New referrer successfully added.' }
        format.json { render :show, status: :ok, location: @issue }
      else
        format.html { render :edit }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1
  # DELETE /issues/1.json
  def destroy
    @issue.destroy
    respond_to do |format|
      format.html { redirect_to issues_url, notice: 'Issue was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /issues/1/assign
  def assign
    repo = "#{current_user.nickname}/#{issue_params['repo']}"
    # assigns issue to current user on original GitHub 
    github_client.update_issue(repo, issue_params['number'].to_i, :assignee => current_user.nickname)
    respond_to do |format|
      format.html { redirect_to issues_url, notice: "Assigned issue to #{current_user.nickname} on GitHub" }
      format.json { render :show, status: :ok, location: @issue }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_issue
      @issue = Issue.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def issue_params
      params.permit(:id, :url, :title, :body, :created_at, :repo, :notes, :number, :updated_at, :referrer)
    end

    def get_form_data
      params.require(:issue).permit(:id, :url, :title, :body, :repo, :notes, :number, :created_at, :updated_at, :referrer)
    end

    def github_client
      authToken = current_user.auth
      client = Octokit::Client.new(:access_token => authToken)
      client
    end

    def username
      current_user.nickname
    end

    def load_suggestions
      begin
      # fancy active record queries to get issues that have been referred to you
      @suggested_issues = Issue.all.where('referrer like ?', "%#{current_user.nickname}%")
      rescue
        @suggested_issues = nil
      end
    end
end
