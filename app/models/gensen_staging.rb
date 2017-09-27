class GensenStaging < ApplicationRecord
  belongs_to :picture
  validates :picture, presence: true

  def self.stage _r, sentence:
    return GensenStaging.new picture_id: _r.picture_id,
                             method: _r.method,
                             confidence_rank: _r.confidence_rank,
                             sentence: sentence
  end

  # GensenStaging.build id: 0, path: 'domain_val.json'
  def self.build limit: -1, id:, path:
    ActiveRecord::Base.connection.execute('TRUNCATE gensen_stagings RESTART IDENTITY')
    sqls = 'INSERT INTO gensen_stagings (picture_id, method, confidence_rank, sentence, created_at, updated_at) VALUES '
    time_s = Time.now

    just_shutup_and do
      Gensen.remove_color_adjectives(limit: limit).each do |k, v|
        a = v[0]
        b = v[1]

        a.each do |confidence_rank, sentence|
          if a[confidence_rank] != b[confidence_rank]
            if a[confidence_rank]
              val_a = "(#{k}, 0, #{confidence_rank}, #{ActiveRecord::Base.connection.quote(a[confidence_rank])}, '#{time_s}', '#{time_s}')"
              ActiveRecord::Base.connection.execute(sqls + val_a)
            end

            if b[confidence_rank]
              val_b = "(#{k}, 1, #{confidence_rank}, #{ActiveRecord::Base.connection.quote(b[confidence_rank])}, '#{time_s}', '#{time_s}')"
              ActiveRecord::Base.connection.execute(sqls + val_b)
            end
          end
        end
      end
    end

    GensenStaging.cache_domain id: id, path: path
    return GensenStaging.count
  end

  def self.build_t60 id:, path:, truncate: false
    if truncate
      ActiveRecord::Base.connection.execute('TRUNCATE gensen_stagings RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE cached_domains RESTART IDENTITY')
    end

    sqls = 'INSERT INTO gensen_stagings (picture_id, method, confidence_rank, sentence, created_at, updated_at) VALUES '
    time_s = Time.now

    h = JSON.parse(File.read(Rails.root.join('db', 't60', path)))
    ps = Hash.new

    Picture.select('id, coco_internal_id').each do |v|
      ps[v[:coco_internal_id]] = v[:id]
    end

    just_shutup_and do
      h.each do |e|
        coco_id = e['image_id']
        caption = e['caption']
        picture_id = ps[coco_id]

        v = "(#{picture_id}, #{id}, 1, #{ActiveRecord::Base.connection.quote(caption)}, '#{time_s}', '#{time_s}')"
        ActiveRecord::Base.connection.execute(sqls + v)
        CachedDomain.create! domain_id: 0,
                             picture_id: picture_id
      end
    end
  end

  def self.cache_domain id:, path:
    j = JSON.parse(File.read(Rails.root.join('public', path)))
    images = j['images'].map{ |x| x['id'].to_i }
    in_staging = Picture.where(coco_internal_id: GensenStaging.pluck(:picture_id).uniq).pluck(:coco_internal_id)
    domains = images & in_staging

    just_shutup_and do
      CachedDomain.where(domain_id: id).destroy_all

      Picture
        .where('pictures.coco_internal_id' => domains).each do |r|
        CachedDomain.create! domain_id: id,
                             picture_id: r.id
      end
    end

    return CachedDomain.where(domain_id: id).count
  end

  def self.just_shutup_and
    ActiveRecord::Base.transaction do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      yield

      ActiveRecord::Base.logger = old_logger
    end
  end
end
