class DomainsController < ApplicationController
  def build
    classes = params[:rest].split('/')
    valtrain = params[:vt]
    @images = Picture.fetch_by_class(type: valtrain, classes: classes)

    render 'index'
  end

  def make_ground_truth
    classes = params[:rest].split('/')
    valtrain = params[:vt]
    render json: Picture.fetch_by_class(type: valtrain, 
                                        classes: classes, 
                                        with_annotations: true)
  end
end
