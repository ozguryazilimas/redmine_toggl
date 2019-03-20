
# Redmine Toggl Plugin

[Redmine Toggl](/) is a [Redmine](https://www.redmine.org) plugin to synchronize [Toggl](https://www.toggl.com) time tracking tool entries with Redmine time entries.


## Features

* Synchronize Toggl entries for users that has Toggl API key set in Redmine
* Automatically create / update / delete Redmine time entry for related issue
* Time entry activities can be mapped to tags on Toggl entries. You can define which Toggl tag matches which Redmine time entry activity on Redmine Admin plugin settings page.
* User interface in Redmine for viewing (with search, sort etc. support) and managing entries
* Create new entry, will create the entry in Toggl and sync to Redmine
* Edit entries (description, start time, duration, project, task workspace both in Toggl and in Redmine), will also update related Redmine time entry if any
* Delete entry, will delete from Toggl and Redmine if any. Currently if you delete the entry on Toggl, it is not deleted from Redmine automatically.
* User rights are controlled with Redmine [permissions](#permissions)


## Synchronization

During synchronization Toggl entry descriptions are parsed. If a description has hashtag followed by a number it is assumed that the entry is
created for Redmine issue number used in the hashtag. Hashtag can be anywhere in the description, there should not be space or other characters
between the hashtag and issue number. All the following descriptions are for Redmine issue number 54321

    investigation for #54321
    #54321 implement new layout

If issue number is detected in description, and that issue exists in Redmine, a Redmine time entry will be created for that issue. Duration
and description (without the issue number part) will be setup in the newly created time entry.

If an entry is received again it is compared with what is recorded in Redmine, and if it has changed the related changes are done.
Ex: if an entry used to be related to issue 54321, but the description has changed and the hashtag is no longer in description,
Redmine time entry that used to be related to the Toggl entry is deleted (and vice versa). Other changes (description, duration etc.)
are also synchronized.


## Installation

Go to plugins directory under your Redmine installation

```
cd /path/to/redmine/plugins
```

and put Redmine Toggl in plugins directory. For example, if you want to use the latest code in master branch you can clone the repository with git

```
git clone https://github.com/zaburt/redmine_toggl.git
```

Go to your Redmine installation directory, install necessary gems with bundler and migrate plugins to create the necessary database tables.

```
RAILS_ENV=production bundle install
RAILS_ENV=production bundle exec rake redmine:plugins:migrate
```

Restart Redmine. You will notice that in user profile pages there are two new custom fields

* Toggl API Key: API token to be used to interact with Toggl. Every users API token must be configured separately. You can get your own token from [Toggl Profile](https://toggl.com/app/profile) page.
* Toggl Workspace: Optional. If set, only entries for given workspace will be synchronized. Multiple workspaces can be defined comma separated. If left blank, all workspaces will be synchronized.

You need at least one user API token set and at least one user that has permission in Toggl to see Toggl projects and tasks lists.
Assuming Redmine user with login **zaburt** has API token configured in Redmine, and has permission in Toggl to get list of projects and tasks
synchronize Toggl base data.

```
RAILS_ENV=production bundle exec rake toggl:sync_base_data[zaburt]
```

You only need to synchronize base data once. If you update projects or tasks in Toggl you can run the rake task again to update in Redmine.

If you want to add user specific workspaces to the system you can run the following task. Note that if a user specific workspace is added, user created entries are always set to use that workspace.

```
RAILS_ENV=production bundle exec rake toggl:sync_base_data_for_user[zaburt,"Zaburt's Workspace"]
```


## Rake Tasks

Synchronize Toggl entries for all active Redmine users, that has their API token set in users profile. By default Toggl API provides entries for about last 9 days
and maximum number of 1000 entries per user. See [Toggl API docs](https://github.com/toggl/toggl_api_docs/blob/master/chapters/time_entries.md#get-time-entries-started-in-a-specific-time-range)
for more information.

```
RAILS_ENV=production bundle exec rake toggl:sync_time_entries
```

You can also give a time range to sync time entries, time values must be in UTC. Note that Toggl API limitations still apply but you can call the rake task multiple times for different
time ranges to synchronize larger time range. To fetch entries between "2016-01-10 12:00" and "2016-01-11 12:00" use the following command. Blank values will be ignored.

```
RAILS_ENV=production bundle exec rake toggl:sync_time_entries["2016-01-10 12:00","2016-01-11 12:00"]
```

Currently Toggl does not provide information on deleted entries if you are fetching multiple time entries, that is why sync_time_entries task does not delete entries
that were deleted from Toggl but that are still in Redmine. If you want to delete these entries from Redmine too you can try the sync_time_entries_remove_missing
task, which will first do what sync_time_entries does, and then tries to figure out if an entry was deleted from Toggl by comparing latest Toggl data and records
in Redmine database. This will take slightly more time, though should be working smart so difference is not big. If you want real synchronization run this task instead.

There is one catch with this approach, if you have say 10 entries in Toggl, sync them to Redmine, then only add a new entry to Toggl (entry 11 becomes latest entry)
and then delete it this rake task will not catch the deletion at first run. However, once you add another entry to Toggl, system will detect the deletion and
remove the entry from Redmine.

You can combine both tasks if you want. For example, you can keep on running sync_time_entries how often you prefer (say once every hour) and run sync_time_entries_remove_missing
instead at midnight, thus the removing synchronization will happen once a day. Rake task parameters are the same with sync_time_entries and they are not mandatory.

```
RAILS_ENV=production bundle exec rake toggl:sync_time_entries_remove_missing
```

To receive list of Toggl Entries that are not associated with a Redmine issue you can run the following rake task. Args are in the format of "started_after,stopped_before,recipients,language".
Started after option decides Toggl Entries started since how many hours ago, stopped before option detects entries stopped before given hours. Started after or stopped before options can be
given zero or blank ("") value to indicate "any". Recipients can be multiple email address pipe "|" separated. Language is optional, default is Redmine default.

```
RAILS_ENV=production bundle exec rake toggl:report_without_issue[24,0,"bob@example.com|john@example.com","en"]
```

You can also get the same report for Toggl Entries that do not have Toggl Project selected

```
RAILS_ENV=production bundle exec rake toggl:report_without_project[24,0,"bob@example.com|john@example.com","en"]
```

Sending reports for entries without project or without issue to users is also possible, these will send different emails to all active users that have
Toggl API key set in their profiles and that have missing project or issue. Email language will be what is configured in users profile.

```
RAILS_ENV=production bundle exec rake toggl:report_without_issue_to_users[24]
RAILS_ENV=production bundle exec rake toggl:report_without_project_to_users[24,1]
```

All rake tasks must be run in the Redmine installation location.


## Scheduling

You can also schedule rake tasks to be run periodically by setting up a cron entry. Cron configuration is dependent on
the operating system Redmine is installed in and which cron implementation is used, refer to related documentation on
how to setup cron. On a system where cron is working properly you can open cron editor to schedule
a rake task execution, the following command will bring up cron editor

```
crontab -e
```

Ex: configure cron to synchronize every hour at 20th minute (10:20, 11:20 etc.)

```
20 * * * * cd /path/to/redmine && RAILS_ENV=production bundle exec rake toggl:sync_time_entries
```


## Permissions

Manage what users can do with Redmine permissions.

* View Toggl entries: Has access to view Toggl entries. Also can edit / create / update if **Toggl API key** is set for user.
* Edit all Toggl entries: Update or delete Toggl entries of other users. Changes will be synchronized to Toggl as the entries original creator.
* Create Toggl time entry to all issues: Allows creating time entries for issues that are not visible to user. Without this permission, even if the issue number in description is found in the system, we do not create time entry.


## License

Copyright (c) 2016 - 2018 Onur Küçük. Licensed under [GNU GPLv2](LICENSE)


