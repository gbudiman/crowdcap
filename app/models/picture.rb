class Picture < ApplicationRecord
  has_many :picture_contents
  has_many :contents, through: :picture_contents

  def self.fetch_by_class type:, classes:
    type_pattern = type == 'val' ? 'COCO_val2014%' : 'COCO_train2014%'

    return Picture
      .joins(:picture_contents)
      .joins(:contents)
      .where('pictures.name LIKE :type_pattern', type_pattern: type_pattern)
      .where('contents.title IN (:classes)', classes: classes)
      .distinct
      .order('pictures.name')
      .pluck('pictures.name')
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
end
