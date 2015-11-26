Rails.application.routes.draw do
  root 'sessions#home'
  get 'sessions/new'

  get 'loads_delivery' => 'loads_delivery#list'

  get 'load_planning' => 'loads#index'

  resources :order_releases
  post 'save_orders' => 'order_releases#save_orders'

  get 'get_available_orders' => 'loads#get_available_orders'
  get 'get_planning_orders' => 'loads#get_planning_orders'
  post 'submit_orders' => 'loads#submit_orders'
  post 'return_orders' => 'loads#return_orders'
  post 'reorder_planning_orders' => 'loads#reorder_planning_orders'
  post 'complete_load' => 'loads#complete_load'
  post 'split_order' => 'loads#split_order'


  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  delete 'logout' => 'sessions#destroy'
  get 'logout' => 'sessions#destroy'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
