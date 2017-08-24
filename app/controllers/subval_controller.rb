class SubvalController < ApplicationController
  include DatasetHelper

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

    broadcast
  end

  def fetch
    render json: Gensen.get_random
  end

  def fetch_all
    @data = Gensen.get_dataset
    render 'subval/dataset_fetch'
  end

  def tally
    @stats = Subval.get_scores
  end

  def get_tally_denorm
    render json: Subval.denorm(index_offset: (params[:index_offset] || 0).to_i)
  end

  def get_domain_dump

    @data = CachedDomain.dump_domain(id: params[:id].to_i, rank: (params[:rank] || 1).to_i)
    render 'subval/dataset'
  end

private
  def broadcast
    ActionCable.server.broadcast 'valmon_notifications_channel', message: Subval.get_scores
  end
end
