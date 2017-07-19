import pprint
import json
import numpy as np

from sklearn.cluster import SpectralClustering
from db_definition import DBSetup

def init_data():
  db = DBSetup()
  data = db.get_workable_features()
  features = []
  serialized = []

  for iid, idata in data.iteritems():
    features.append(idata['feature_vector'])
    serialized.append({
      'picture_id': iid,
      'picture_name': idata['picture_name'],
    })

  return {
    'serialized': serialized,
    'features': features
  }

def init_algorithm(features):
  algo = SpectralClustering(8)
  algo.fit(np.asarray(features))

  return algo

def output_clustering(serialized, labels):
  results = {}
  for img, _label in zip(serialized, labels):
    label = str(_label)
    if label not in results:
      results[label] = []

    results[label].append(img)

  with open('output/out.json', 'w') as outfile:
    json.dump(results, outfile, sort_keys=True, indent=2)


input_data = init_data()
algo = init_algorithm(input_data['features'])
output_clustering(input_data['serialized'], algo.labels_)