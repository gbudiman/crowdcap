class CachedDomain < ApplicationRecord
  belongs_to :picture
  validates :picture, presence: true

  def self.pick_random id:, rank:
    return CachedDomain.get_cached(id: id, rank: rank)
                       .order('RANDOM()')
                       .first
  end

  def self.get_dataset id:, rank:
    return CachedDomain.get_cached(id: id, rank: rank)
  end

  def self.dump_domain id:, rank:
    conn = ActiveRecord::Base.connection

    sql = "SELECT pictures.coco_internal_id AS coco_id,
                  g_a.sentence AS google,
                  g_b.sentence AS domain,
                  g_a_raw.sentence AS google_raw,
                  g_b_raw.sentence AS domain_raw
             FROM cached_domains
             INNER JOIN pictures
               ON pictures.id = cached_domains.picture_id
             INNER JOIN gensen_stagings AS g_a
                ON pictures.id = g_a.picture_id
               AND g_a.method = 0
               AND g_a.confidence_rank = #{conn.quote(rank)}
             INNER JOIN gensen_stagings AS g_b
                ON pictures.id = g_b.picture_id
               AND g_b.method = 1
               AND g_b.confidence_rank = #{conn.quote(rank)}
             INNER JOIN gensens AS g_a_raw
                ON pictures.id = g_a_raw.picture_id
               AND g_a_raw.method = 0
               AND g_a_raw.confidence_rank = #{conn.quote(rank)}
             INNER JOIN gensens AS g_b_raw
                ON pictures.id = g_b_raw.picture_id
               AND g_b_raw.method = 1
               AND g_b_raw.confidence_rank = #{conn.quote(rank)}
             WHERE domain_id = #{conn.quote(id)}
            "

    return ActiveRecord::Base.connection.execute(sql)
  end

  def self.get_cached id:, rank:
    return CachedDomain.where(domain_id: id)
                       .joins(:picture)
                       .joins("INNER JOIN gensen_stagings AS g_a 
                                  ON pictures.id = g_a.picture_id 
                                 AND g_a.method = 0 
                                 AND g_a.confidence_rank = #{rank}")
                       .joins("INNER JOIN gensen_stagings AS g_a 
                                  ON pictures.id = g_a.picture_id 
                                 AND g_a.method = 0 
                                 AND g_a.confidence_rank = #{rank}")
  end
end
