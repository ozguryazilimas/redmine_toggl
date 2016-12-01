
# Redmine Toggl Plugin

[Redmine Toggl](/) is a [Redmine](https://www.redmine.org) plugin to synchronize [Toggl](https://www.toggl.com) time tracking tool entries with Redmine time entries.


## Features

* Synchronize Toggl entries for usersi that has Toggl API key set in Redmine
* Automatically create Redmine time entry for related issue
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

Go to your Redmine installation directory and migrate plugins to create the necessary database tables.

```
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


## Rake Tasks

Synchronize Toggl entries for all active Redmine users, that has their API token set in users profile. By default Toggl API provides entries for about last 9 days
and maximum number of 1000 entries per user. See [Toggl API docs](https://github.com/toggl/toggl_api_docs/blob/master/chapters/time_entries.md#get-time-entries-started-in-a-specific-time-range)
for more information.

```
RAILS_ENV=production bundle exec rake toggl:sync_time_entries
```

All rake tasks must be run in the Redmine installation location. You can also schedule rake tasks to be run periodically by setting up a cron entry. Cron configuration is dependent on
the operating system Redmine is installed in and which cron implementation is used, refer to related documentation on how to setup cron. On a system where cron is working properly you can open cron editor to schedule
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


## License

Copyright (c) 2016 Onur Küçük. Licensed under [GNU GPLv3](COPYING)


