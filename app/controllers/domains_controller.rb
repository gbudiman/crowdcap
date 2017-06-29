class DomainsController < ApplicationController
  def build
    classes = params[:rest].split('/')
    valtrain = params[:vt]
    images = Picture.fetch_by_class(type: valtrain, classes: classes)

    render partial: 'index', locals: { images: images }
  end
end
