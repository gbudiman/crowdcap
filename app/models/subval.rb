class Subval < ApplicationRecord
  def self.denorm
    h = []
    score_a_sum = 0
    score_b_sum = 0
    score_dmos = 0
    count = 0

    Subval
      .joins('INNER JOIN gensens AS g_a ON a_id = g_a.id')
      .joins('INNER JOIN gensens AS g_b ON b_id = g_b.id')
      .joins('INNER JOIN pictures ON g_a.picture_id = pictures.id')
      .select('pictures.coco_internal_id AS picture_coco_id',
              'pictures.name AS picture_name',
              'g_a.sentence AS sentence_a',
              'g_b.sentence AS sentence_b',
              'subvals.a_score AS a_score',
              'subvals.b_score AS b_score',
              'subvals.updated_at AS timestamped')
      .order('created_at' => :desc)
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

      count = count + 1
      score_a_sum = score_a_sum + r.a_score
      score_b_sum = score_b_sum + r.b_score
      score_dmos = score_dmos + (r.b_score - r.a_score)
    end

    return {
      res: h,
      score_a_sum: score_a_sum,
      score_b_sum: score_b_sum,
      score_dmos: score_dmos,
      count: count
    }
  end
end
