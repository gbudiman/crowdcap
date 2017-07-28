class MergedCaption < ApplicationRecord
  belongs_to :picture
  validates :picture, presence: true

  def self.build
    ActiveRecord::Base.connection.execute('TRUNCATE merged_captions RESTART IDENTITY')
    MergedCaption.extract_json Rails.root.join('public', 'merged_val_annotations.json'), :val
    MergedCaption.extract_json Rails.root.join('public', 'merged_train_annotations.json'), :train
  end

  def self.extract_json io, type
    h = {}
    Picture.all.each do |r|
      h[r.coco_internal_id] = r.id
    end

    ActiveRecord::Base.transaction do
      old_logger = ActiveRecord::Base.logger
      #ActiveRecord::Base.logger = nil

      JSON.parse(File.read(io)).each do |s|
        internal_id = s['id'].to_i
        coco_id = s['image_id']

        MergedCaption.create!(picture_id: h[coco_id],
                              caption: s['caption'],
                              coco_internal_id: internal_id)
      end

      #ActiveRecord::Base.logger = old_logger
    end
  end
end
