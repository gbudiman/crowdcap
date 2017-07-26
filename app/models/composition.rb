class Composition < ApplicationRecord
  has_many :pictures

  def self.build
    contents = Composition.invert_contents

    ActiveRecord::Base.transaction do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      pictures = {}
      Picture
        .joins(:contents)
        .select('pictures.id AS picture_id',
                'contents.id AS content_id')
        .each do |row|
        pictures[row.picture_id] ||= Set.new
        pictures[row.picture_id].add row.content_id
      end

      pictures.tqdm.each do |picture_id, content_set|
        content_sorted = content_set.to_a.sort
        content_textual = Array.new
        content_sql = "{#{content_sorted.join(',')}}"

        comps = Composition.where('contents = :cs', cs: content_sql)
        comp_id = nil
        if comps.length == 0
          content_sorted.each do |c|
            content_textual.push contents[c]
          end

          content_textual_sql = "{#{content_textual.join(',')}}"
          new_composition = Composition.create contents: content_sql,
                                               content_textual: content_textual_sql

          comp_id = new_composition.id
        else
          comp_id = comps.first.id
        end

        picture = Picture.find(picture_id)
        picture.composition_id = comp_id
        picture.save
      end

      ActiveRecord::Base.logger = old_logger
    end
  end

  def self.find_pictures _cs
    if _cs.is_a?(Hash)
    elsif _cs.is_a?(Array)
      content_ids = Content.where(title: _cs).pluck(:id).sort
    else
      content_ids = Content.where(title: _cs).pluck(:id).sort
    end

    Composition
      .joins(:pictures)
      .where(contents: to_sql_array(content_ids))
      .pluck('pictures.id')
    
  end

private
  def self.to_sql_array x
    return "{#{x.join(',')}}"
  end

  def self.invert_contents
    contents = {}
    Content.all.as_json.each do |d|
      contents[d['id']] = d['title']
    end

    return contents
  end
end
