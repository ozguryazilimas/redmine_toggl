
RedmineApp::Application.routes.draw do

  resources :toggl_entries do
    collection do
      get :all_entries
      get 'filter_by_user/:filter_user_id', :action => :filter_by_user, :as => :filter_by_user
    end
  end

end

