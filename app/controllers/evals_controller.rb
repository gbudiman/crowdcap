class EvalsController < ApplicationController
  def index
  end

  def fetch
    render json: Potential.fetch_random
  end

  def post
    render json: Potential.submit_eval(id: params[:id], val: params[:val])
  end
end
