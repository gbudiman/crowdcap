class Caption < ApplicationRecord
  belongs_to :picture
  validates :picture, presence: true

  def self.build
    Caption.extract_json Rails.root.join('public', 'captions_val2014.json'), :val
    Caption.extract_json Rails.root.join('public', 'captions_train2014.json'), :train
  end

  def self.extract_json io, type
    h = {}
    Picture.all.each do |r|
      h[r.name] = r.id
    end

    ActiveRecord::Base.connection.execute('TRUNCATE captions RESTART IDENTITY')
    ActiveRecord::Base.transaction do
      pretext = "COCO_#{type == :val ? 'val' : 'train'}2014_"
      JSON.parse(File.read(io))['annotations'].each do |s|
        coco_id = pretext + sprintf("%012d.jpg", s['image_id'])
        Caption.create picture_id: h[coco_id,
                       caption: s['caption']
      end
    end
  end
end
