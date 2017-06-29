Rails.application.routes.draw do
  get      '/evals'            , to: 'evals#index'
  get      '/evals/fetch'      , to: 'evals#fetch'
  post     '/evals/post'       , to: 'evals#post'
  get      '/domains/:vt/*rest', to: 'domains#build'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end