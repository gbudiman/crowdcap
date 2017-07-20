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
        .each do |p|
        pictures[picture_id] ||= Set.new
        pictures[picture_id].add content_id
      end

      pictures.tqdm.each do |picture_id, content_set|
        content_sorted = content_set.to_a.sort
        content_textual = Array.new

        content_sorted.each do |c|
          content_textual.push contents[c]
        end

        Composition.find_or_create_by(content: content_sorted)
      end

      ActiveRecord::Base.logger = old_logger
    end
  end

  def self.invert_contents
    contents = {}
    Contents.all.as_json.each do |d|
      contents[d['title']] = d['id']
    end

    return contents
  end
end
