# this file runs scripts on the database to keep it up-to-date
import threading
import datetime
import time
import json
import datetime

import shared

# runs scripts to maintain database in a separate thread
def setup_and_run_maintenance():
    thread = threading.Thread(target = run_maintenance)
    thread.start()
    thread.join()
    print("thread finished... this should never happen")


def run_maintenance():
    while True:
        sleep_until_utc_midnight()
        purge_old_infected_users_list()
        migrate_all_infected_user_reports()


def sleep_until_utc_midnight():
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


# delete the previous day's distribution list
def purge_old_infected_users_list():
    yday = datetime.datetime.utcnow() + datetime.timedelta(days=-1)
    shared.REDIS_CLIENT.delete(shared.REDIS_DISTRIBUTE_INFECTED_USERS_KEY.format(yday.year, yday.month, yday.day))


# migrate each user into the distribution list
# [todo] do not delete the list as that could lose data if this function fails
# instead, archive the key for a few days before deleting for better resiliency
def migrate_all_infected_user_reports():
    pipeline = shared.REDIS_CLIENT.pipeline()
    pipeline.lrange(shared.REDIS_LATEST_INFECTED_USERS_KEY, 0, -1)
    pipeline.delete(shared.REDIS_LATEST_INFECTED_USERS_KEY)
    responses = pipeline.execute()
    user_list = responses[0]

    for user_data in user_list:
        data = json.loads(user_data)
        date = datetime.datetime.strptime(data['date'], shared.DATE_FORMAT)
        key = shared.REDIS_DISTRIBUTE_INFECTED_USERS_KEY.format(date.year, date.month, date.day)
        shared.REDIS_CLIENT.rpush(key, data['user_id'])

