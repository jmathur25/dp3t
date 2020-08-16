''' configurations '''

import redis
import os

REDIS_CLIENT = redis.Redis(host='redis', db=0, socket_timeout=5)

# redis constants
REDIS_DISTRIBUTE_INFECTED_USERS_KEY = "distribute_infected_users"
REDIS_LATEST_INFECTED_USERS_KEY = "latest_infected_users"

# other constants
MAX_DAY_STORAGE = 14
ID_LENGTH = 64
DATE_FORMAT = "%Y-%m-%d"

# testing params
IS_TEST = False
if os.getenv("IS_TEST") == 'true':
    IS_TEST = True
