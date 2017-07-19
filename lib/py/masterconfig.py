class Config:
  config = {
    'dbuser': 'gbudiman',
    'dbpassword': '80ae19F@'
  }

  @staticmethod
  def get(x):
    return Config.config[x] 