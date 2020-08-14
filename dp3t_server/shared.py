import logging
import redis

REDIS_CLIENT = redis.Redis(host='localhost', port=6379, db=0)
if not REDIS_CLIENT.ping():
    logging.fatal("error: could not ping redis")

# redis constants
REDIS_DISTRIBUTE_INFECTED_USERS_KEY = "distribute_infected_users:{}:{}:{}"
REDIS_LATEST_INFECTED_USERS_KEY = "latest_infected_users"

# other constants
MAX_DAY_STORAGE = 14
ID_LENGTH = 26
DATE_FORMAT = "%Y/%M/%d"

