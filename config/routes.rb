Gridinit::Application.routes.draw do

  get 'pages/home'

  match '/runs/retest/:id'            => 'runs#retest'
  match '/runs/share/:id'             => 'runs#share'
  match '/runs/compare/:id'           => 'runs#compare'
  match '/runs/public/:id'            => 'runs#set_public'
  match '/runs/private/:id'           => 'runs#set_private'
  match '/runs/status/:id'            => 'runs#status'
  match '/runs/quickie/*source'       => 'runs#quickie'
  match '/runs/abort_running_tests'   => 'runs#abort_running_tests'
  match '/runs/delete_queued_tests'   => 'runs#delete_queued_tests'
  match '/runs/delete_all_tests'      => 'runs#delete_all_tests'
  match '/runs/notes'                 => 'runs#notes'

  match '/dashboard/hits'             => 'dashboard#hits'
  match '/dashboard/stats'            => 'dashboard#stats'
  match '/shared'                     => 'dashboard#shared'
  
  match '/nodes/restart/:id'          => 'nodes#restart'
  
  resources :nodes, :constraints  => { :id => %r([^/;,?]+) }
  resources :scores
  resources :errors, :constraints => {:id => /[\w.]+?/, :format => /html|json|png/}
  resources :indices
  resources :testdata
  resources :dashboard
  resources :charts
  resources :logs
  resources :attachments
  resources :runs
  resources :health
 
  match '/auth/:provider/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'
  match '/signout' => 'sessions#destroy', :as => :signout
  match '/signin/:provider' => 'sessions#new', :as => :signin

  mount Resque::Server, :at => "/resque"
 
  root :to => 'pages#home'
end