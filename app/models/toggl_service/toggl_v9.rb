
class TogglService
  class TogglV9
    include Connection

    NAME = 'Redmine Toggl'
    TOGGL_API_BASE_URL = 'https://api.track.toggl.com/api/v9'
    TOGGL_API_TOKEN = 'api_token'


    def initialize(api_token)
      auth_args = {
        :username => api_token,
        :password => TOGGL_API_TOKEN
      }

      @toggl_url = TOGGL_API_BASE_URL

      setup_authentication(auth_args)
    end

    def workspaces
      http_call :get, 'me/workspaces'
    end

    def projects(workspace_id)
      http_call :get, "workspaces/#{workspace_id}/projects"
    end

    def tasks(workspace_id)
      http_call :get, "workspaces/#{workspace_id}/tasks"
    end

    def get_time_entries(args = {})
      api_args = {}

      [:start_date, :end_date].each do |date_type|
        api_args[date_type] = iso8601(args[date_type]) if args[date_type].present?
      end

      http_call :get, 'me/time_entries', api_args
    end

    def get_time_entry(time_entry_id)
      http_call :get, "me/time_entries/#{time_entry_id}"
    end

    def create_time_entry(args)
      args['created_with'] = NAME
      workspace_id = args['workspace_id']

      if !args.has_key?('workspace_id') && !args.has_key?('project_id') && !args.has_key?('task_id')
        raise ArgumentError, 'please provide only one of workspace_id, project_id or task_id'
      end

      http_call :post, "workspaces/#{workspace_id}/time_entries", args
    end

    def update_time_entry(time_entry_id, workspace_id, args)
      http_call :put, "workspaces/#{workspace_id}/time_entries/#{time_entry_id}", args
    end

    def delete_time_entry(time_entry_id, workspace_id)
      http_call :delete, "workspaces/#{workspace_id}/time_entries/#{time_entry_id}"
    end

    def iso8601(timestamp)
      return nil if timestamp.blank?

      formatted_ts = if timestamp.is_a?(DateTime) || timestamp.is_a?(Date)
                       timestamp.iso8601
                     elsif timestamp.is_a?(String)
                       DateTime.parse(timestamp).iso8601
                     else
                       raise ArgumentError, "Can not convert #{timestamp.inspect} to ISO8601"
                     end

      formatted_ts.sub('+00:00', 'Z')
    end

  end
end

