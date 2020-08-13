# this file runs scripts on the database to keep it up-to-date
import threading
import datetime
import time
import json
import datetime

from .globals import (
    REDIS_CLIENT,
    REDIS_DISTRIBUTE_INFECTED_USERS_KEY,
    REDIS_LATEST_INFECTED_USERS_KEY,
    DATE_FORMAT,
)


# runs scripts to maintain database in a separate thread
def setup_maintenance():
    thread = threading.Thread(target = run_maintenance)
    thread.start()
    thread.join()
    print("thread finished... this should never happen")


def run_maintenance():
    while True:
        start_time = datetime.datetime.utcnow()
        next_midnight = start_time + \
                        datetime.timedelta( \
                            days=1, \
                            hours=-start_time.hour, \
                            minutes=-start_time.minute, \
                            seconds=-start_time.second,
                        )
        sleep_time = (next_midnight - start_time).total_seconds()
        time.sleep(sleep_time)
        purge_old_infected_users_list()
        migrate_all_infected_user_reports()


# delete the current distribution list
def purge_old_infected_users_list():
    REDIS_CLIENT.delete(REDIS_DISTRIBUTE_INFECTED_USERS_KEY)


# migrate each user into the distribution list
# [todo] do not delete the list as that could lose data if function fails
# instead, archive the key for a few days before deleting
def migrate_all_infected_user_reports():
    pipeline = REDIS_CLIENT.pipeline()
    pipeline.lrange(REDIS_LATEST_INFECTED_USERS_KEY, 0, -1)
    pipeline.delete(REDIS_LATEST_INFECTED_USERS_KEY)
    responses = pipeline.execute()
    user_list = responses[0]

    for user_data in user_list:
        data = json.loads(user_data)
        date = datetime.datetime.strptime(data['date'], DATE_FORMAT)
        key = REDIS_DISTRIBUTE_INFECTED_USERS_KEY.format(date.year, date.month, date.day)
        REDIS_CLIENT.rpush(key, data)

