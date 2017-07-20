from db_definition import DBSetup

db = DBSetup()
db.fill_cache('val')
db.fill_cache('train')