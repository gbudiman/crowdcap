class SubvalController < ApplicationController
  def index
    render 'index'
  end

  def post
    a_id = params['a_id'].to_i
    b_id = params['b_id'].to_i
    score = params['score'].to_i

    if a_id != -1 then s_a = Gensen.find(a_id).sentence end
    if b_id != -1 then s_b = Gensen.find(b_id).sentence end

    ap params
    Subval.create!(a_id: a_id, b_id: b_id, score: score)

    render json: { response: true }
  end

  def fetch
    render json: Gensen.get_random
  end

  def tally
    d = Subval.denorm
    @res = d[:res]
    @score = d[:score]
    @count = d[:count]
  end
end
