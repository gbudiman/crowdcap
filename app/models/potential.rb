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
                     pquery.name AS query_name,
                     ptarget.name AS target_name')

    first_pot = pot.first
    return {
      response: 'success',
      id: first_pot.pot_id,
      pquery: first_pot.query_name,
      ptarget: first_pot.target_name
    }
  end

  def self.submit_eval(id:, val:)
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
SELECT DISTINCT dq.picture_id
  FROM (
    SELECT subq.picture_id,
           subq.picture_name,
           subq.object,
           COUNT(*) OVER (PARTITION BY subq.picture_name) AS object_count
      FROM (
        SELECT pictures.id AS picture_id,
               pictures.name AS picture_name,
               contents.title AS object
          FROM pictures
          INNER JOIN picture_contents AS pc
            ON pc.picture_id = pictures.id
          INNER JOIN contents
            ON pc.content_id = contents.id
          WHERE ::object_union::
            AND pictures.name LIKE \'COCO_train2014%\'
          GROUP BY pictures.id,
                   pictures.name,
                   contents.title
      ) AS subq
  ) AS dq
  WHERE dq.object_count = ::object_count::
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
      object_union = objects.map{|x| "contents.title = '#{x}'"}.join(' OR ')
      object_count = objects.length

      this_matcher = matcher.dup
      this_matcher.sub!('::object_union::', object_union)
                  .sub!('::object_count::', object_count.to_s)

      executor = ActiveRecord::Base.connection.execute(this_matcher)

      ActiveRecord::Base.transaction do
        executor.each do |m|
          #puts "#{id} -> #{m['picture_id']}"
          Potential.create(query_id: id, target_id: m['picture_id'])
        end
      end

    end

    ActiveRecord::Base.logger = old_logger
  end
end
