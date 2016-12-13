
class TogglEntriesController < ApplicationController
  unloadable

  before_filter :set_toggl_entry, :only => [:show, :edit, :update, :destroy]
  before_filter :authorize_global
  before_filter :user_can_create_toggl_entry, :only => [:new, :create]

  helper_method :user_can_create_toggl_entry, :user_can_edit_toggl_entry, :user_can_edit_all_toggl_entries


  def index
    @user = User.current

    respond_to do |format|
      format.html
      format.json {
        render :json => TogglEntriesDatatable.new(TogglEntry, view_context, @user.id)
      }
    end
  end

  def all_entries
    @user = User.current

    respond_to do |format|
      format.html
      format.json {
        render :json => TogglEntriesDatatable.new(TogglEntry, view_context)
      }
    end
  end

  def show
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
    Rails.logger.error e
    flash.now[:error] = e.message
    render :new
  end

  def edit
  end

  def update
    raise Unauthorized unless user_can_edit_toggl_entry(@toggl_entry)

    toggl = TogglService.new(:user => @toggl_entry.user)
    toggl.update_time_entry(toggl_entry_params)
    redirect_to @toggl_entry, :notice => t('toggl.toggl_entry_updated')
  rescue => e
    Rails.logger.error e
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

  def set_toggl_entry
    @toggl_entry = TogglEntry.find(params[:id])
  end

  def toggl_entry_params
    params.require(:toggl_entry).permit(
      :description, :start, :stop, :duration, :toggl_id, :user_id,
      :toggl_workspace_id, :toggl_project_id, :toggl_task_id
    )
  end

  def user_can_create_toggl_entry
    User.current.toggl_can_create_toggl_entry
  end

  def user_can_edit_all_toggl_entries
    User.current.allowed_to_globally?(:edit_all_toggl_entries)
  end

  def user_can_edit_toggl_entry(toggl_entry)
    (toggl_entry.user.id == User.current.id) || user_can_edit_all_toggl_entries
  end
end

