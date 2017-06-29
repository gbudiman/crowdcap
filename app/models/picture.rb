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
      .pluck('pictures.name')
  end
end
