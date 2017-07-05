# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.paths << '/Users/gbudiman/Documents/captioning/port/test_images'
Rails.application.config.assets.paths << '/media/b10/gbudiman-coco/coco/images/train2014'
Rails.application.config.assets.paths << '/media/b10/gbudiman-coco/coco/images/val2014'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( style.css
                                                  animate.css
                                                  evals/*.js
                                                  layout/*.js )
