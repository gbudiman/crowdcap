class DomainsController < ApplicationController
  def build
    classes = params[:rest].split('/')
    valtrain = params[:vt]

    render json: Picture.fetch_by_class(type: valtrain, classes: classes)
  end
end
