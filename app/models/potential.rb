class Potential < ApplicationRecord
  def self.fetch_random
    sql = 'SELECT ROUND(RANDOM() * (SELECT MAX(id) FROM potentials)) AS id'
    id = nil
    ActiveRecord::Base.connection.execute(sql).each do |r|
      id = r['id'].to_i
    end

    pot = Potential
            .where('potentials.id = :id', id: id)
            .joins('INNER JOIN pictures AS pquery ON potentials.query_id = pquery.id')
            .joins('INNER JOIN pictures AS ptarget ON potentials.target_id = ptarget.id')
            .select('potentials.id AS pot_id,
                     pquery.id AS query_picture_id,
                     pquery.name AS query_name,
                     ptarget.id AS target_picture_id,
                     ptarget.name AS target_name')

    first_pot = pot.first
    objects_in_q = Set.new(Picture.find(first_pot.query_picture_id).contents.pluck(:title))
    #objects_in_t = Set.new(Picture.find(first_pot.target_picture_id).contents.pluck(:title))

    #ap objects_in_q
    #ap objects_in_t
    return {
      response: 'success',
      id: first_pot.pot_id,
      pquery: first_pot.query_name,
      ptarget: first_pot.target_name,
      objects: objects_in_q
    }
  end

  def self.submit_eval(id:, val:)
    pot = Potential.find(id)
    pot.increment :count_evaluated
    if val == 'good'
      pot.increment :count_correct
    end

    return {
      response: 'success'
    }
  end

  def self.build
    sql = '''
SELECT filt.picture_id,
       filt.object
  FROM (  
    SELECT subq.picture_id AS picture_id,
           subq.picture_name AS picture_name,
           subq.object AS object,
           subq.object_count AS object_count,
           COUNT(*) OVER (PARTITION BY subq.picture_id, subq.picture_name) AS distinct_objects,
           SUM(subq.object_count) OVER (PARTITION BY subq.picture_id, subq.picture_name) AS total_objects
      FROM (
        SELECT pictures.id AS picture_id,
               pictures.name AS picture_name,
               contents.title AS object,
               COUNT(*) AS object_count
          FROM pictures
            INNER JOIN picture_contents
              ON pictures.id = picture_contents.picture_id
            INNER JOIN contents
              ON picture_contents.content_id = contents.id
          WHERE pictures.name LIKE \'COCO_val2014%\'
          GROUP BY pictures.id,
                   pictures.name,
                   contents.title
      ) AS subq
  ) AS filt
  WHERE filt.distinct_objects > 1
    AND CAST(filt.distinct_objects AS FLOAT) / CAST(filt.total_objects AS FLOAT) >= 0.5'''

    matcher = <<-MATCHER
SELECT DISTINCT subq.picture_id,
                subq.picture_name,
                subq.object_name
  FROM
    (SELECT pictures.id AS picture_id,
           pictures.name AS picture_name,
           contents.title AS object_name,
           COUNT(*) OVER (PARTITION BY pictures.name) AS object_count
      FROM pictures
      INNER JOIN picture_contents AS pc
        ON pc.picture_id = pictures.id
      INNER JOIN contents
        ON pc.content_id = contents.id
      WHERE pictures.id IN
        (SELECT pictures.id
          FROM pictures
          INNER JOIN picture_contents AS pc
            ON pc.picture_id = pictures.id
          INNER JOIN contents
            ON pc.content_id = contents.id
          WHERE contents.title IN (::object_union::)
            AND pictures.name LIKE \'COCO_train2014%\'
        )
      GROUP BY pictures.id,
               pictures.name,
               contents.title
    ) AS subq
  WHERE subq.object_count = ::object_count::
  ORDER BY subq.picture_id, subq.object_name
MATCHER

    valdata = {}
    ActiveRecord::Base.connection.execute('TRUNCATE potentials RESTART IDENTITY')
    Potential.destroy_all

    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    ActiveRecord::Base.connection.execute(sql).each do |r|
      picture_id = r['picture_id'].to_i
      valdata[picture_id] ||= Array.new

      valdata[picture_id].push(r['object'])
    end

    

    valdata.tqdm.each do |id, objects|
      object_union = objects.map{|x| "'#{x}'"}.join(', ')
      object_count = objects.length
      valdata_object_set = Set.new(objects)

      this_matcher = matcher.dup
      this_matcher.sub!('::object_union::', object_union)
                  .sub!('::object_count::', object_count.to_s)

      executor = ActiveRecord::Base.connection.execute(this_matcher)

      ActiveRecord::Base.transaction do
        traindata = {}

        executor.each do |m|
          traindata[m['picture_id']] ||= Array.new
          traindata[m['picture_id']].push(m['object_name'])
          #puts "#{id} -> #{m['picture_id']}"
          #Potential.create(query_id: id, target_id: m['picture_id'])
        end

        traindata.each do |picture_id, objects|
          traindata_object_set = Set.new(objects)
          set_union = traindata_object_set + valdata_object_set
          set_intersect = traindata_object_set & valdata_object_set

          if (set_union == set_intersect) and (set_union.length == set_intersect.length)
            #ap set_union
            #ap set_intersect
            Potential.create(query_id: id, target_id: picture_id)
          end
        end
      end

    end

    ActiveRecord::Base.logger = old_logger
  end
end
