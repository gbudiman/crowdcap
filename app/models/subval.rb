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

  def self.get_stats
    result = Array.new

    sql = 'select distinct g.coco_id as coco_id,
           g.path as path,
           count(g.a_score) over (partition by g.coco_id) as eval_count,
           min(g.a_score) over (partition by g.coco_id) as min_a,
           avg(g.a_score) over (partition by g.coco_id) as avg_a,
           max(g.a_score) over (partition by g.coco_id) as max_a,
           min(g.b_score) over (partition by g.coco_id) as min_b,
           avg(g.b_score) over (partition by g.coco_id) as avg_b,
           max(g.b_score) over (partition by g.coco_id) as max_b,
           min(g.dmos) over (partition by g.coco_id) as min_dmos,
           avg(g.dmos) over (partition by g.coco_id) as avg_dmos,
           max(g.dmos) over (partition by g.coco_id) as max_dmos,
           g.sentence_a as sentence_a,
           g.sentence_b as sentence_b
           from (
             select g_a.sentence as sentence_a,
                    g_b.sentence as sentence_b,
                    subvals.a_score as a_score,
                    subvals.b_score as b_score,
                    subvals.b_score - subvals.a_score as dmos,
                    pictures.name as path,
                    pictures.coco_internal_id as coco_id
             from subvals
             inner join gensen_stagings as g_a
               on subvals.a_id = g_a.id
             inner join gensen_stagings as g_b
               on subvals.b_id = g_b.id 
             inner join pictures
               on g_a.picture_id = pictures.id
           ) as g
           order by coco_id'

    ActiveRecord::Base.connection.execute(sql).each do |r|
      result.push r
    end

    return result
  end
end
