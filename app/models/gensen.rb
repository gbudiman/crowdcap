class Gensen < ApplicationRecord
  belongs_to :picture
  validates :picture, presence: true

  @@gen_method = {
    google: 0,
    gdomain: 1
  }

  @@color_lut = {
      "gray" => true,
    "purple" => true,
      "pink" => true,
     "green" => true,
    "yellow" => true,
      "blue" => true,
     "brown" => true,
       "red" => true,
     "black" => true,
     "white" => true,
  }

  @@object_lut = {
    woman: 'person',
    women: 'people',
    man: 'person',
    men: 'people',
    girl: 'person',
    girls: 'people',
    boy: 'person',
    boys: 'people',
    children: 'people',
    child: 'person',
    kid: 'person',
    kids: 'people'
  }

  def self.get_random
    h = {
      picture: {},
      methods: {}
    }
    method_container = {}
    s_picture_id = nil
    s_gensen_id = nil

    GensenStaging
      .joins(:picture)
      .where(picture_id: CachedDomain.pick_random(id: 0, rank: 1).picture_id)
      .select('pictures.id AS picture_id',
              'pictures.name AS picture_name',
              'gensen_stagings.id AS gensen_id',
              'gensen_stagings.method AS method_id',
              'gensen_stagings.sentence AS sentence')
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

  # Most common build commands:
  # Gensen.build path: 'google_coco_val_2014', mode: :google
  # Gensen.build path: 'gdomain_val_2014', mode: :gdomain
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
        workload[:sentences].each_with_index do |sentence, i|
          sqls.push([h[coco_picture_id], h_method, i+1, sentence])
        end
      end

      raw_sql = 'INSERT INTO gensens (picture_id, method, confidence_rank, sentence, created_at, updated_at) VALUES '
      vals = sqls.map{|x| "(#{x[0]}, #{x[1]}, #{x[2]}, #{ActiveRecord::Base.connection.quote(x[3])}, '#{time_s}', '#{time_s}')"}.join(', ')

      ActiveRecord::Base.connection.execute(raw_sql + vals)
    end

    return Gensen.all.length
  end

  def self.load_adjectives limit: -1
    tagger = EngTagger.new
    adjs = {}
    dataset = limit == -1 ? Gensen.all : Gensen.all.first(limit)
    dataset.tqdm.each do |r|
      tagged = tagger.add_tags(r.sentence)
      tagger.get_adjectives(tagged).each do |k, v|
        adjs[k] ||= 0
        adjs[k] = adjs[k] + v
      end
    end
  end

  def self.remove_color_adjectives limit: -1
    tagger = EngTagger.new
    prefilter = Gensen.all
    dataset = limit == -1 ? prefilter : prefilter.first(limit)
    staging = {}

    dataset.tqdm.each do |r|
      tagged = tagger.add_tags(r.sentence)
      adjectives = tagger.get_adjectives(tagged)
      nouns = tagger.get_nouns(tagged)
      sentence = r.sentence.dup
      modification_count = 0

      bicolor_match = sentence.match(/(\w+)\s+and\s+(\w+)/)

      if bicolor_match
        
        actual_bicolors = bicolor_match.to_a.select do |x| 
          @@color_lut[x] != nil 
        end

        if actual_bicolors.length == 2
          modification_count = 2
          sentence.gsub!(/#{actual_bicolors[0]}\s+and\s+#{actual_bicolors[1]}/, '')
        end
      end

      adjectives.each do |adjective, _junk|
        if @@color_lut[adjective]
          modification_count = modification_count + 1
          sentence.gsub!(adjective, '')
        end
      end

      nouns.each do |_noun, _junk|
        noun = _noun.downcase.to_sym
        object_modification = @@object_lut[noun]
        if object_modification
          modification_count = modification_count + 1
          sentence.gsub!(_noun, object_modification)
        end
      end

      staging[r.picture_id] ||= {
        0 => {},
        1 => {}
      }

      # if (modification_count > 0)
      #   ap r.sentence
      #   ap " ==> #{sentence}"
      #   ap '---'
      # end

      staging[r.picture_id][r.method][r.confidence_rank] = retain_only_words(sentence)
    end

    return staging
  end

  def self.retain_only_words x
    return x.gsub(/[^\w\s\d]+/, '').gsub(/\s+/, ' ').strip
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
