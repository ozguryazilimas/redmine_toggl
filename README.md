
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



## Permissions



## License

Copyright (c) 2016 Onur Küçük. Licensed under [GNU GENERAL PUBLIC LICENSE version 3](COPYING)


