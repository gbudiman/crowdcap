class SubvalController < ApplicationController
  def index
  end

  def post
    
  end

  def fetch
    render json: Gensen.get_random
  end
end
