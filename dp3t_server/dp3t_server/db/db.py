'''
this file runs scripts on the database to keep it up-to-date
'''

import threading
import datetime
import time
import json
import datetime
import logging

import config


# runs scripts to maintain database in a separate thread
def setup_and_run_maintenance():
    if not config.IS_TEST:
        logging.info("setting up maintenance script...")
        thread = threading.Thread(target=run_maintenance)
        thread.start()
    else:
        logging.info("just a test, returning out...")


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
    config.REDIS_CLIENT.delete(config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY.format(yday.year, yday.month, yday.day))


# migrate each user into the distribution list
# [todo] do not delete the list as that could lose data if this function fails
# instead, archive the key for a few days before deleting for better resiliency
def migrate_all_infected_user_reports():
    pipeline = config.REDIS_CLIENT.pipeline()
    pipeline.lrange(config.REDIS_LATEST_INFECTED_USERS_KEY, 0, -1)
    pipeline.delete(config.REDIS_LATEST_INFECTED_USERS_KEY)
    responses = pipeline.execute()
    user_list = responses[0]

    for user_data in user_list:
        data = json.loads(user_data)
        date = datetime.datetime.strptime(data['date'], config.DATE_FORMAT)
        key = config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY.format(date.year, date.month, date.day)
        config.REDIS_CLIENT.rpush(key, data['user_id'])

