class DomainsController < ApplicationController
  def build
    classes = params[:rest].split('/')
    valtrain = params[:vt]
    @images = Picture.fetch_by_class(type: valtrain, classes: classes)

    render 'index'
  end
end
