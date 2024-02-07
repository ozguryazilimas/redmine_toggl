namespace :toggl do

  desc 'Sync user time entries'
  task :sync_time_entries, [:start_date, :end_date] => :environment do |t, args|
    sync_args = {}
    sync_args[:start_date] = args[:start_date] if args[:start_date].present?
    sync_args[:end_date] = args[:end_date] if args[:end_date].present?

    ts_response = TogglService.sync_toggl_time_entries(sync_args)
    format_toggl_service_errors(ts_response)
  end

  desc 'Sync user time entries and remove entries still in Redmine but deleted from Toggl'
  task :sync_time_entries_remove_missing, [:start_date, :end_date] => :environment do |t, args|
    sync_args = {}
    sync_args[:start_date] = args[:start_date] if args[:start_date].present?
    sync_args[:end_date] = args[:end_date] if args[:end_date].present?

    ts_response = TogglService.sync_toggl_time_entries(sync_args, true)
    format_toggl_service_errors(ts_response)
  end

  desc 'Sync workspace, project and task base data, delete workspaces without users'
  task :sync_base_data, [:user] => :environment do |t, args|
    user_login = args[:user]

    if user_login.blank?
      puts 'Please provide a user. User Toggl API key will be used to sync base data. Sample command for user with login "bob"'
      puts '  RAILS_ENV=production bundle exec rake toggl:sync_base_data[bob]'
      exit
    end

    user = User.find_by_login(user_login)

    unless user
      puts "User #{user_login} not found"
      exit
    end

    apikey = user.cf_toggl_api_key

    if apikey.blank?
      puts "Toggl API Key for user #{user_login} is not setup. Please set it up in users settings."
      exit
    end

    puts "Before sync Workspace: #{TogglWorkspace.count} Project: #{TogglProject.count} Task: #{TogglTask.count}"
    TogglService.sync_base_data(apikey)
    puts "After sync  Workspace: #{TogglWorkspace.count} Project: #{TogglProject.count} Task: #{TogglTask.count}"
  end

  desc 'Sync workspace for a specific user and keep workspaces already saved'
  task :sync_base_data_for_user, [:user, :workspace] => :environment do |t, args|
    user_login = args[:user]
    workspace_name = args[:workspace]

    if user_login.blank? || workspace_name.blank?
      puts 'Please provide a user and workspace name. User Toggl API key will be used to sync base data. Sample command for user with login "bob" and workspace "My Workspace"'
      puts '  RAILS_ENV=production bundle exec rake toggl:sync_base_data_for_user[bob,"My Workspace"]'
      exit
    end

    user = User.find_by_login(user_login)

    unless user
      puts "User #{user_login} not found"
      exit
    end

    apikey = user.cf_toggl_api_key

    if apikey.blank?
      puts "Toggl API Key for user #{user_login} is not setup. Please set it up in users settings."
      exit
    end

    puts "Before sync Workspace: #{TogglWorkspace.count} Project: #{TogglProject.count} Task: #{TogglTask.count}"
    TogglService.sync_base_data(apikey, workspace_name, user)
    puts "After sync  Workspace: #{TogglWorkspace.count} Project: #{TogglProject.count} Task: #{TogglTask.count}"
  end

  desc 'Sends email with a list of Toggl entries that are not assigned to an issue'
  task :report_without_issue, [:started_after, :stopped_before, :recipients, :language] => :environment do |t, args|
    started_after = arg_to_hours_ago(args[:started_after])
    stopped_before = arg_to_hours_ago(args[:stopped_before])
    recipients = args[:recipients].to_s.split('|')
    language = args[:language]

    if recipients.blank?
      puts 'Please provide recipient email address, you can provide multiple address pipe "|" separated'
      exit
    else
      recipients.each do |recipient|
        next unless recipient.match(TogglEntry::EMAIL_VALIDATOR).nil?

        puts "Invalid email address #{recipient.inspect}"
        exit
      end
    end

    results = TogglEntry.report_without_issue(started_after, stopped_before)
    Mailer.toggl_report_without_issue(User.anonymous, recipients, results, language, started_after, stopped_before).deliver_now
  end

  desc 'Sends email with a list of Toggl entries that are not assigned to a Toggl Project'
  task :report_without_project, [:started_after, :stopped_before, :recipients, :language] => :environment do |t, args|
    started_after = arg_to_hours_ago(args[:started_after])
    stopped_before = arg_to_hours_ago(args[:stopped_before])
    recipients = args[:recipients].to_s.split('|')
    language = args[:language]

    if recipients.blank?
      puts 'Please provide recipient email address, you can provide multiple address pipe "|" separated'
      exit
    else
      recipients.each do |recipient|
        next unless recipient.match(TogglEntry::EMAIL_VALIDATOR).nil?

        puts "Invalid email address #{recipient.inspect}"
        exit
      end
    end

    results = TogglEntry.report_without_project(started_after, stopped_before)
    Mailer.toggl_report_without_project(User.anonymous, recipients, results, language, started_after, stopped_before).deliver_now
  end

  desc 'Sends email to all active Toggl users with a list of Toggl entries that are not assigned to an issue'
  task :report_without_issue_to_users, [:started_after, :stopped_before] => :environment do |t, args|
    started_after = arg_to_hours_ago(args[:started_after])
    stopped_before = arg_to_hours_ago(args[:stopped_before])

    User.active.with_toggl_api_key.each do |user|
      recipients = user.mail
      language = user.language

      results = TogglEntry.report_without_issue_for_user(user, started_after, stopped_before)
      next if results.blank?
      Mailer.toggl_report_without_issue(user, recipients, results, language, started_after, stopped_before).deliver_now
    end
  end

  desc 'Sends email to all active Toggl users with a list of Toggl entries that are not assigned to a Toggl Project'
  task :report_without_project_to_users, [:started_after, :stopped_before] => :environment do |t, args|
    started_after = arg_to_hours_ago(args[:started_after])
    stopped_before = arg_to_hours_ago(args[:stopped_before])

    User.active.with_toggl_api_key.each do |user|
      next if user.toggl_workspace

      recipients = user.mail
      language = user.language

      results = TogglEntry.report_without_project_for_user(user, started_after, stopped_before)
      next if results.blank?
      Mailer.toggl_report_without_project(user, recipients, results, language, started_after, stopped_before).deliver_now
    end
  end

  desc 'Export all Toggl entries to redmine_toggl.csv file'
  task :export_to_csv, [:file_name, :start_date, :end_date] => :environment do |t, args|
    export_args = {}
    export_args[:start_date] = args[:start_date] if args[:start_date].present?
    export_args[:end_date] = args[:end_date] if args[:end_date].present?
    file_name = args[:file_name].presence || 'redmine_toggl.csv'

    csv_data = TogglEntry.export_to_csv(export_args)

    File.open file_name, 'w' do |f|
      f.write csv_data
    end
  end

  def arg_to_hours_ago(timeval)
    time_in_int = timeval.to_i
    return nil unless time_in_int > 0
    time_in_int.hours.ago
  end

  def format_toggl_service_errors(ts_response)
    return if ts_response.blank? || ts_response[:errors].blank?

    raise error[:error] unless error[:error] =~ /^HTTP Status: 4/

    ts_response[:errors].each do |login, errors|
      errors.each do |error|
        formatted = format(
          'ERROR FOR USER: %s MESSAGE: %s TOGGL_ENTRY: %s',
          login,
          error[:error],
          (error[:toggl_entry].presence || I18n.t('toggl.toggl_could_not_fetch'))
        )

        STDERR.puts formatted
      end

      user = User.find_by_login(login)
      next unless user

      Mailer.toggl_report_invalid_user_toggl_entry(user, errors, user.language).deliver_now
    end
  end
end

