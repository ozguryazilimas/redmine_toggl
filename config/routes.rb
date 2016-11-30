
RedmineApp::Application.routes.draw do

  resources :toggl_entries do
    collection do
      get :all_entries
    end
  end

end

