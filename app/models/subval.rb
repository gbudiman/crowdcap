class Subval < ApplicationRecord
  def self.denorm
    h = []

    Subval
      .joins('INNER JOIN gensens AS g_a ON a_id = g_a.id')
      .joins('INNER JOIN gensens AS g_b ON b_id = g_b.id')
      .joins('INNER JOIN pictures ON g_a.picture_id = pictures.id')
      .select('pictures.coco_internal_id AS picture_coco_id',
              'pictures.name AS picture_name',
              'g_a.sentence AS sentence_a',
              'g_b.sentence AS sentence_b',
              'subvals.score AS score',
              'subvals.created_at AS timestamped')
      .order('created_at' => :desc)
      .each do |r|
      h.push({
        sentence_a: r.sentence_a,
        sentence_b: r.sentence_b,
        timestamped: r.timestamped,
        score: r.score,
        picture: r.picture_name,
        picture_coco_id: r.picture_coco_id
      })
    end

    return h
  end
end
