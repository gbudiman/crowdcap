class SubvalController < ApplicationController
  def index
    render 'index'
  end

  def post
    a_id = params['a_id'].to_i
    b_id = params['b_id'].to_i
    a_score = params['a_score'].to_i
    b_score = params['b_score'].to_i
    subval_id = params['subval_id'].to_i

    if params['subval_id'].blank?
      sv = Subval.create!(a_id: a_id, b_id: b_id, a_score: a_score, b_score: b_score)

      render json: {
        success: true,
        id: sv.id
      }
    else
      sv = Subval.find(subval_id)

      sv.a_score = a_score
      sv.b_score = b_score
      sv.save!

      render json: {
        success: true,
        id: sv.id
      }
    end
    # score = params['score'].to_i

    # if a_id != -1 then s_a = Gensen.find(a_id).sentence end
    # if b_id != -1 then s_b = Gensen.find(b_id).sentence end

    # ap params
    # Subval.create!(a_id: a_id, b_id: b_id, score: score)

    # render json: { response: true }
  end

  def fetch
    render json: Gensen.get_random
  end

  def tally
    d = Subval.denorm
    @res = d[:res]
    @score_a_sum = d[:score_a_sum]
    @score_b_sum = d[:score_b_sum]
    @score_dmos = d[:score_dmos]
    @count = d[:count]
  end
end
