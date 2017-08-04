class Gensen < ApplicationRecord
  belongs_to :picture
  validates :picture, presence: true

  @@gen_method = {
    google: 0,
    gdomain: 1
  }

  def self.get_random
    h = {
      picture: {},
      methods: {}
    }
    method_container = {}
    s_picture_id = nil
    s_gensen_id = nil

    # Gensen
    #   .joins(:picture)
    #   .limit(1)
    #   .order('RANDOM()')
    #   .select('pictures.id AS picture_id', 
    #           'pictures.name AS picture_name',
    #           'gensens.id AS gensen_id',
    #           'gensens.method AS method_id',
    #           'gensens.sentence AS sentence')
    #   .where()
    #   .each do |r|
    #   h[:picture][:id] ||= r.picture_id
    #   h[:picture][:name] ||= r.picture_name
    #   method_id = r.method_id

    #   h[:methods][method_id] = {
    #     id: r.gensen_id,
    #     text: r.sentence
    #   }

    #   s_picture_id = r.picture_id
    #   s_gensen_id = r.gensen_id
    # end

    raw_sql = 
      'select pictures.id as picture_id,
              pictures.name as picture_name,
              gensens.id AS gensen_id,
              gensens.method AS method_id,
              gensens.sentence as sentence
        from gensens
        inner join pictures
          on gensens.picture_id = pictures.id
        where picture_id = (
          select picture_id
            from gensens
            where method = 1
            order by random()
            limit 1
        )'

    #ActiveRecord::Base.connection.execute(raw_sql).each do |r|
    Gensen
      .joins(:picture)
      .where(picture_id: Picture.pick_from_domain.id)
      .select('pictures.id AS picture_id',
              'pictures.name AS picture_name',
              'gensens.id AS gensen_id',
              'gensens.method AS method_id',
              'gensens.sentence AS sentence')
      .order(:id)
      .each do |r|
      h[:picture][:id] = r['picture_id']
      h[:picture][:name] = r['picture_name']

      h_method = r['method_id']
      method_container[h_method] ||= Hash.new
      method_container[h_method][r['gensen_id']] = {
        text: r['sentence'],
        id: r['gensen_id']
      }
    end

    method_a_sample = method_container[0][method_container[0].keys()[0]]
    method_b_sample = method_container[1][method_container[1].keys()[0]]

    h[:methods][0] = method_a_sample
    h[:methods][1] = method_b_sample

    #h[:methods][99] = {
    #  id: -1,
    #  text: "Randomly generated at #{Time.now}"
    #}

    #h[:methods][99] = Gensen.get_placeholder(picture_id: s_picture_id, mask_id: s_gensen_id)
    return h
  end

  def self.get_placeholder picture_id:, mask_id:
    h = {}

    Gensen
      .limit(1)
      .order('RANDOM()')
      .select('gensens.id AS gensen_id',
              'gensens.sentence AS sentence')
      .where('gensens.picture_id = :pid', pid: picture_id)
      .where('gensens.id != :mid', mid: mask_id)
      .each do |r|
      h[:id] = r.gensen_id
      h[:text] = r.sentence
    end

    return h
  end

  def self.build path:, mode:, truncate: false
    workloads = Hash.new
    h_method = @@gen_method[mode]
    if h_method == nil 
      raise RuntimeError, "Unrecognized sentence generation method: #{mode}"
    end

    Dir.foreach(Rails.root.join('db', 'gensen', path)) do |item|
      item_match = item.match(/(\d{12,12})\.txt$/)
      if item_match
        coco_picture_id = item_match[1].to_i
        workloads[coco_picture_id] = {
          path: Rails.root.join('db', 'gensen', path, item).to_s,
          sentences: Array.new
        }
      end
    end

    workloads.tqdm.each do |coco_picture_id, workload|
      path = workload[:path]
      File.readlines(path).each do |_line|
        #puts line
        #line_match = line.match(/(^))
        line = _line.gsub(/[\(]?p=.+/, '').gsub("\n", '')
        workload[:sentences].push line
      end
    end

    if truncate then ActiveRecord::Base.connection.execute('TRUNCATE gensens RESTART IDENTITY') end

    just_shutup_and do
      h = {}
      Picture.all.each do |pic|
        h[pic.coco_internal_id] = pic.id
      end

      sqls = []
      time_s = Time.now
      workloads.tqdm.each do |coco_picture_id, workload|
        workload[:sentences].each do |sentence|
          sqls.push([h[coco_picture_id], h_method, sentence])
        end
      end

      raw_sql = 'INSERT INTO gensens (picture_id, method, sentence, created_at, updated_at) VALUES '
      vals = sqls.map{|x| "(#{x[0]}, #{x[1]}, #{Gensen.sanitize(x[2])}, '#{time_s}', '#{time_s}')"}.join(', ')

      ActiveRecord::Base.connection.execute(raw_sql + vals)
    end

    return Gensen.all.length
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
