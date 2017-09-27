class Subval < ApplicationRecord
  def self.denorm index_offset: 0, batch_size: 25
    h = []
    batch = batch_size == -1 ? Subval.count : batch_size
    # score_a_sum = 0
    # score_b_sum = 0
    # score_dmos = 0
    # count = 0

    Subval
      .joins('INNER JOIN gensen_stagings AS g_a ON a_id = g_a.id')
      .joins('INNER JOIN gensen_stagings AS g_b ON b_id = g_b.id')
      .joins('INNER JOIN pictures ON g_a.picture_id = pictures.id')
      .select('pictures.coco_internal_id AS picture_coco_id',
              'pictures.name AS picture_name',
              'g_a.sentence AS sentence_a',
              'g_b.sentence AS sentence_b',
              'subvals.a_score AS a_score',
              'subvals.b_score AS b_score',
              'subvals.updated_at AS timestamped')
      .order('created_at' => :desc)
      .limit(batch)
      .offset(batch * index_offset)
      .each do |r|
      h.push({
        sentence_a: r.sentence_a,
        sentence_b: r.sentence_b,
        timestamped: r.timestamped,
        score_a: r.a_score,
        score_b: r.b_score,
        score_dmos: r.b_score - r.a_score,
        picture: r.picture_name,
        picture_coco_id: r.picture_coco_id
      })

      # count = count + 1
      # score_a_sum = score_a_sum + r.a_score
      # score_b_sum = score_b_sum + r.b_score
      # score_dmos = score_dmos + (r.b_score - r.a_score)
    end

    # return {
    #   res: h,
    #   score_a_sum: score_a_sum,
    #   score_b_sum: score_b_sum,
    #   score_dmos: score_dmos,
    #   count: count
    # }

    return h
  end

  def self.get_scores
    result = {}

    Subval
      .select('SUM(a_score) AS a_score',
              'SUM(b_score) AS b_score',
              'COUNT(*) AS count')
      .each do |r|

      a_score = (r.a_score || 0).to_f
      b_score = (r.b_score || 0).to_f
      count = (r.count || 0).to_i
      diff = b_score - a_score
      result[:mos_a] = a_score == 0 ? 0 : a_score / count.to_f
      result[:mos_b] = b_score == 0 ? 0 : b_score / count.to_f
      result[:dmos] = diff == 0 ? 0 : diff / count.to_f
      result[:count] = count
    end

    return result
  end
end
