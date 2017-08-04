class Picture < ApplicationRecord
  has_many :picture_contents
  has_many :contents, through: :picture_contents
  has_many :captions
  has_many :merged_captions
  has_many :gensens
  has_one :composition

  @@domains = Array.new

  def self.populate_domains
    j = JSON.parse(File.read(Rails.root.join('public', 'domain_val.json')))
    images = j['images']

    images.each do |image|
      @@domains.push(image['id'].to_i)
    end
  end

  def self.pick_from_domain
    if @@domains.length == 0 then Picture.populate_domains end
    return Picture.find_by(coco_internal_id: @@domains.sample)
  end

  def self.domain_size
    return @@domains.length
  end

  def self.generate_caption id
    return Picture.find(id).captions.pluck(:caption).sample
  end

  def self.build_metadata
    Picture.extract_json Rails.root.join('public', 'captions_val2014.json'), :val
    Picture.extract_json Rails.root.join('public', 'captions_train2014.json'), :train
  end

  def self.extract_json io, type
    ActiveRecord::Base.transaction do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      JSON.parse(File.read(io))['images'].each do |s|
        picture = Picture.find_by(name: s['file_name'])
        picture.coco_internal_id = s['id']
        picture.height = s['height']
        picture.width = s['width']
        picture.save
      end

      ActiveRecord::Base.logger = old_logger
    end
  end

  def self.build_domain type:
    k = fetch_by_class type: type,
                       classes: ['bicycle','car','traffic light','fire hydrant','motorcycle','stop sign','parking meter','bus','truck'],
                       with_annotations: true

    File.open(Rails.root.join('public', "domain_#{type}.json"), 'w') do |f|
      f.write k.to_json
    end

  end

  def self.fetch_by_class type:, classes:, with_annotations: false
    type_pattern = type == 'val' ? 'COCO_val2014%' : 'COCO_train2014%'

    picture = Picture
      .joins(:picture_contents)
      .joins(:contents)
      .where('pictures.name LIKE :type_pattern', type_pattern: type_pattern)

    if classes == ['all']
    else
      picture = picture.where('contents.title IN (:classes)', classes: classes)
    end

    if with_annotations
      annotations = []
      images = []
      image_processed = {}

      picture.joins(:merged_captions)
        .select('pictures.name AS picture_name',
                'pictures.coco_internal_id AS picture_internal_id',
                'pictures.height AS picture_height',
                'pictures.width AS picture_width',
                'merged_captions.caption AS sentence',
                'merged_captions.coco_internal_id AS caption_internal_id')
        .distinct
        .each do |r|
        #matches = /(\d{12,12})/.match(r.picture_name)
        annotation = {
          image_id: r.picture_internal_id, #matches[1].to_i,
          id: r.caption_internal_id,
          caption: r.sentence
        }
        annotations.push annotation

        if image_processed[r.picture_internal_id]
        else
          image = {
            id: r.picture_internal_id,
            file_name: r.picture_name,
            height: r.picture_height,
            width: r.picture_width 
          }

          images.push image
          image_processed[r.picture_internal_id] = true
        end
      end

      return {
        images: images,
        annotations: annotations
      }
    else
      return picture.distinct
                    .order('pictures.name')
                    .pluck('pictures.name')
    end
  end

  def self.detected_objects
    results = {}

    Picture.joins(:contents)
      .distinct
      .select('pictures.name AS picture_name',
              'contents.title AS object_name').each do |r|
      filename_matcher = /(\d{12,12})/.match(r.picture_name)
      coco_id = filename_matcher[1].to_i

      results[coco_id] ||= Array.new
      results[coco_id].push(r.object_name)
    end

    File.open('public/detected_objects.json', 'w') do |f|
      f.write(results.to_json)
    end
  end

  def self.measure_detection_accuracy valtrain:
    dbjson = JSON.parse(File.read('public/detected_objects.json'))
    gtjson = JSON.parse(File.read("public/objects_#{valtrain}.json"))
    extra_left = {}
    extra_right = {}
    translations = {
      'airplane' => 'aeroplane',
      'dining table' => 'diningtable',
      'motorcycle' => 'motorbike',
      'potted plant' => 'pottedplant',
      'tv' => 'tvmonitor',
    }
    classes = {}
    metrics = {
      fully_accurate: 0,
      extra_data: 0,
      all: gtjson.length
    }

    # left = DBset
    # right = GTset
    File.open('public/detection_comparison.txt', 'w') do |f|
      gtjson.each do |sid, gt_data|
        db_data = dbjson[sid]
        dbset = Set.new db_data
        gtset = Set.new

        gt_data.each do |g|
          gtset.add(translations[g] || g)
        end
        
        intersect = dbset & gtset
        union = dbset + gtset
        list_left = dbset - intersect
        list_right = gtset - intersect

        list_left.to_a.each do |l|
          extra_left[l] ||= 0
          extra_left[l] = extra_left[l] + 1

          classes[l] ||= {
            left: 0,
            right: 0,
            center: 0
          }

          classes[l][:left] = classes[l][:left] + 1
        end

        list_right.to_a.each do |r|
          extra_right[r] ||= 0
          extra_right[r] = extra_right[r] + 1

          classes[r] ||= {
            left: 0,
            right: 0,
            center: 0
          }

          classes[r][:right] = classes[r][:right] + 1
        end

        intersect.to_a.each do |c|
          classes[c] ||= {
            left: 0,
            right: 0,
            center: 0
          }

          classes[c][:center] = classes[c][:center] + 1
        end

        if list_left.length == 0 and list_right.length == 0
          s = ''
          metrics[:fully_accurate] = metrics[:fully_accurate] + 1
        else
          if list_right.length == 0
            metrics[:extra_data] = metrics[:extra_data] + 1
          end
          s = "#{list_left.to_a.join(', ')} << [#{intersect.to_a.join(', ')}] >> #{list_right.to_a.join(', ')}"
        end

        t = "%12d | %3d / %3d | %s\n" % [sid.to_i, intersect.length, gtset.length, s]
        f.write(t)
      end
    end

    ap extra_left.sort.to_h
    ap extra_right.sort.to_h
    ap metrics

    puts "%24s | %6s | %6s | %6s | %6s" % ['Classes', 'Left', 'Center', 'Right', 'IoU']
    60.times { print '-' }
    puts
    Hash[classes.sort_by{ |k, v| v[:center].to_f / (v[:left] + v[:center] + v[:right]).to_f}].each do |key, value|
      puts "%24s | %6d | %6d | %6d | %6.2f" %
        [key,
         value[:left],
         value[:center],
         value[:right],
         value[:center].to_f / (value[:left] + value[:center] + value[:right]).to_f]
    end

    return nil
  end

  def self.display_clustering
    file = File.read(Rails.root.join('lib', 'py', 'output', 'out.json'))
    return JSON.parse(file)
  end

  def self.make_thumbnails
    paths = ['/media/b10/gbudiman-coco/coco/images/train2014', '/media/b10/gbudiman-coco/coco/images/val2014']
    out = Rails.root.join('app', 'assets', 'images')

    paths.each do |path|
      Dir.glob(Rails.root.join(path, '*.jpg')).tqdm.each do |item|
        filename = item.split('/').last
        out_path = Rails.root.join(out, "thumb_#{filename}")
        #puts "#{File.join(path, item)} -> #{out_path}"
        image = MiniMagick::Image.open(item)
        image.resize '64x64'
        image.write out_path
      end
    end
  end
end
