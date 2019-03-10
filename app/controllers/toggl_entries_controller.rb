
class TogglEntriesController < ApplicationController

  before_action :set_toggl_entry, :only => [:show, :edit, :update, :destroy]
  before_action :authorize_global
  before_action :user_can_create_toggl_entry, :only => [:new, :create]
  before_action :user_can_view_others_entries, :only => [:all_entries, :filter_by_user]
  before_action :set_user, :only => [:index, :all_entries, :filter_by_user]
  before_action :parse_toggl_tags, :only => [:create, :update]

  helper_method :user_can_create_toggl_entry, :user_can_edit_toggl_entry, :user_can_edit_all_toggl_entries,
    :user_can_view_others_entries


  def index
    respond_to do |format|
      format.html
      format.json {
        render :json => TogglEntriesDatatable.new(TogglEntry, view_context, @user.id)
      }
    end
  end

  def all_entries
    respond_to do |format|
      format.html
      format.json {
        render :json => TogglEntriesDatatable.new(TogglEntry, view_context)
      }
    end
  end

  def filter_by_user
    @filter_user = User.find(params[:filter_user_id])

    respond_to do |format|
      format.html
      format.json {
        render :json => TogglEntriesDatatable.new(TogglEntry, view_context, @filter_user.id)
      }
    end
  end

  def show
    raise Unauthorized unless user_can_view_toggl_entry(@toggl_entry)
  end

  def new
    @toggl_entry = TogglEntry.new
    @toggl_entry.description = "##{params[:issue_id]} " if params[:issue_id]
  end

  def create
    toggl = TogglService.new(:user => User.current)
    @toggl_entry = toggl.create_time_entry(toggl_entry_params)
    redirect_to @toggl_entry, :notice => t('toggl.toggl_entry_created')
  rescue => e
    Rails.logger.error "Toggl ERROR: #{e.message}\n#{e.backtrace}"
    flash.now[:error] = e.message
    @toggl_entry = TogglEntry.new
    render :new
  end

  def edit
    raise Unauthorized unless user_can_edit_toggl_entry(@toggl_entry)
  end

  def update
    raise Unauthorized unless user_can_edit_toggl_entry(@toggl_entry)

    toggl = TogglService.new(:user => @toggl_entry.user)
    toggl.update_time_entry(toggl_entry_params)
    redirect_to @toggl_entry, :notice => t('toggl.toggl_entry_updated')
  rescue => e
    Rails.logger.error "Toggl ERROR: #{e.message}\n#{e.backtrace}"
    flash.now[:error] = e.message
    render :edit
  end

  def destroy
    raise Unauthorized unless user_can_edit_toggl_entry(@toggl_entry)

    @toggl_entry.sync_and_destroy
    redirect_to toggl_entries_url, :notice => t('toggl.toggl_entry_deleted')
  rescue => e
    Rails.logger.error e
    flash[:error] = e.message
    redirect_to toggl_entries_url, :notice => e.message
  end

  private

  def set_user
    @user = User.current
  end

  def set_toggl_entry
    @toggl_entry = TogglEntry.find(params[:id])
  end

  def parse_toggl_tags
    params[:toggl_entry][:toggl_tags] = params[:toggl_entry][:toggl_tags].split(TogglEntry::TOGGL_TAG_SEPARATOR)
  end

  def toggl_entry_params
    params.require(:toggl_entry).permit(
      :description, :start, :stop, :duration, :toggl_id, :user_id,
      :toggl_workspace_id, :toggl_project_id, :toggl_task_id, :toggl_tags => []
    )
  end

  def user_can_create_toggl_entry
    User.current.toggl_can_create_toggl_entry
  end

  def user_can_edit_all_toggl_entries
    User.current.allowed_to_globally?(:edit_all_toggl_entries)
  end

  def user_can_edit_toggl_entry(toggl_entry)
    return true if user_can_edit_all_toggl_entries
    user_can_edit_own_entries(toggl_entry)
  end

  def user_can_view_toggl_entry(toggl_entry)
    return true if user_can_view_others_entries
    toggl_entry.user.id == User.current.id
  end

  def user_can_view_others_entries
    User.current.toggl_can_view_others_entries
  end

  def user_can_edit_own_entries(toggl_entry)
    usr = User.current
    time_entry = toggl_entry.time_entry
    user_owns_entry = toggl_entry.user.id == usr.id
    # if no time_entry then there is no issue, so we do not know which project this is for
    return user_owns_entry unless time_entry

    project = time_entry.project
    # allow if the user can edit all time_entries in the project
    return true if usr.allowed_to?(:edit_time_entries, project)

    # if user can not edit others entries, and does not own the entry, they can not edit it
    return false unless user_owns_entry

    # user owns the entry, see if they can edit their own entry
    return usr.allowed_to?(:edit_own_time_entries, project)
  end
end

