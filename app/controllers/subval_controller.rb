class SubvalController < ApplicationController
  def index
    render 'index'
  end

  def post
    a_id = params['a_id'].to_i
    b_id = params['b_id'].to_i

    if a_id != -1 then s_a = Gensen.find(a_id).sentence end
    if b_id != -1 then s_b = Gensen.find(b_id).sentence end

    puts s_a
    puts s_b

    render json: { response: true }
  end

  def fetch
    render json: Gensen.get_random
  end
end
