namespace :toggl do

  desc 'Sync user time entries'
  task :sync_time_entries, [:start_date, :end_date] => :environment do |t, args|
    sync_args = {}
    sync_args[:start_date] = args[:start_date] if args[:start_date].present?
    sync_args[:end_date] = args[:end_date] if args[:end_date].present?

    TogglService.sync_toggl_time_entries(sync_args)
  end

  desc 'Sync workspace, project and task base data'
  task :sync_base_data, [:user] => :environment do |t, args|
    user_login = args[:user]

    if user_login.blank?
      puts 'Please provide a user, users Toggl API key will be used to sync base data. Sample command for user with login "bob"'
      puts '  RAILS_ENV=production bundle exec rake toggl:sync_base_data[bob]'
      exit
    end

    user = User.find_by_login(user_login)

    unless user
      puts "User #{user_login} not found"
      exit
    end

    apikey = user.toggl_api_key

    if apikey.blank?
      puts "Toggl API Key for user #{user_login} is not setup. Please set it up in users settings."
      exit
    end

    puts "Before sync Workspace: #{TogglWorkspace.count} Project: #{TogglProject.count} Task: #{TogglTask.count}"
    TogglService.sync_base_data(apikey)
    puts "After sync  Workspace: #{TogglWorkspace.count} Project: #{TogglProject.count} Task: #{TogglTask.count}"
  end

end

