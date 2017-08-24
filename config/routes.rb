Rails.application.routes.draw do
  get      '/evals'            , to: 'evals#index'
  get      '/evals/fetch'      , to: 'evals#fetch'
  post     '/evals/post'       , to: 'evals#post'
  get      '/domains/clustering', to: 'domains#clustering'
  get      '/domains/fetch/cluster', to: 'domains#fetch_cluster'
  get      '/domains/gt/:vt/*rest', to: 'domains#make_ground_truth'
  get      '/domains/:vt/*rest', to: 'domains#build'
  get      '/caption/:id'      , to: 'evals#caption'
  get      '/subjective/evals' , to: 'subval#index'
  get      '/subjective/evals/fetch', to: 'subval#fetch'
  post     '/subjective/evals/post', to: 'subval#post'
  get      '/subjective/evals/tally', to: 'subval#tally'
  get      '/subjective/evals/notif', to: 'subval#notif'
  get      '/subjective/evals/denorm', to: 'subval#get_tally_denorm'
  get      '/subjective/evals/dataset/:id', to: 'subval#get_domain_dump'
  get      '/subjective/evals/dataset/:id/:rank', to: 'subval#get_domain_dump'

  mount    ActionCable.server => '/cable'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
