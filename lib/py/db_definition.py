from orator import DatabaseManager, Schema
from orator import Model as DBModel
from orator import Collection
from orator.orm import has_one, has_many, belongs_to
from tqdm import tqdm
from masterconfig import Config

import json

class Picture(DBModel):
  @has_one
  def feature(self):
    return Feature

class Feature(DBModel):
  @belongs_to
  def picture(self):
    return Picture

class DBDefinition:
  dbmodel = DBModel

class DBSetup:
  dbmodel = DBModel

  def __init__(self):
    config = {
      'pgsql': {
        'driver': 'pgsql',
        'host': 'localhost',
        'database': 'captioning',
        'user': Config.get('dbuser'),
        'password': Config.get('dbpassword')
      }
    }
    self.db = DatabaseManager(config)
    DBModel.set_connection_resolver(self.db)
    self.schema = Schema(self.db)

  def fill_cache(self, vt):
    results = []
    
    q = Picture.join('picture_contents', 'pictures.id', '=', 'picture_contents.picture_id') \
           .join('contents', 'picture_contents.content_id', '=', 'contents.id') \
           .where_in('contents.title', ['bicycle','car','traffic light','fire hydrant','motorcycle','stop sign','parking meter','bus','truck']) \
           .where('pictures.name', 'like', 'COCO_val2014_%' if vt == 'val' else 'COCO_train2014_%') \
           .select('pictures.id AS picture_id')

    for row in tqdm(q.get()):
      picture_id = row.picture_id

      results.append(picture_id)

    outpath = 'cached_val.json' if vt == 'val' else 'cached_train.json'
    with open('output/' + outpath, 'w') as outfile:
      json.dump(results, outfile)

  def get_cached_features(self, vt):
    results = {}
    path = 'output/cached_' + ('train' if vt == 'train' else 'val') + '.json'
    data = None
    with open(path) as data_file:
      data = json.load(data_file)

    q = Picture.where_in('pictures.id', data) \
               .join('features', 'pictures.id', '=', 'features.picture_id') \
               .select('pictures.id AS picture_id', \
                       'pictures.name AS picture_name', \
                       'pictures.coco_internal_id AS picture_coco_id', \
                       'features.vectors AS feature_vector')

    for row in tqdm(q.get()):
      picture_id = row.picture_id
      picture_name = row.picture_name
      picture_coco_id = row.picture_coco_id
      feature_vector = row.feature_vector

      if picture_id not in results:
        results[picture_id] = {
          'picture_name': picture_name,
          'picture_coco_id': picture_coco_id,
          'feature_vector': feature_vector
        }

    return results

  def get_workable_features(self):
    results = {}
    q = Picture.join('features', 'pictures.id', '=', 'features.picture_id') \
               .join('picture_contents', 'pictures.id', '=', 'picture_contents.picture_id') \
               .join('contents', 'picture_contents.content_id', '=', 'contents.id') \
               .where_in('contents.title', ['car']) \
               .where('pictures.name', 'like', 'COCO_val2014_%') \
               .select('pictures.id AS picture_id', \
                       'pictures.name AS picture_name', \
                       'pictures.coco_internal_id AS picture_coco_id', \
                       'features.vectors AS feature_vector')

    for row in tqdm(q.get()):
      picture_id = row.picture_id
      picture_name = row.picture_name
      picture_coco_id = row.picture_coco_id
      feature_vector = row.feature_vector

      if picture_id not in results:
        results[picture_id] = {
          'picture_name': picture_name,
          'picture_coco_id': picture_coco_id,
          'feature_vector': feature_vector
        }

    return results