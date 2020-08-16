'''
this file runs scripts on the redis database to keep it up-to-date
'''

import threading
import datetime
import time
import logging

import config


# runs scripts to maintain database in a separate thread
def setup_and_run_maintenance():
    if config.IS_TEST:
        logging.info("setting up test maintenance script...")
        thread = threading.Thread(target=run_test_maintenance)
        thread.start()
    else:
        logging.info("setting up maintenance script...")
        thread = threading.Thread(target=run_maintenance)
        thread.start()


# sync users every UTC midnight
def run_maintenance():
    while True:
        sleep_until_utc_midnight()
        purge_infected_users_list()
        migrate_all_infected_user_reports()


# sync the latest changes to the distribution list every second
# does not wipe the old infected users list
def run_test_maintenance():
    logging.info("every second we check for reported users and sync them over...")
    previous_num_users = 0
    while True:
        infected_list = config.REDIS_CLIENT.lrange(config.REDIS_LATEST_INFECTED_USERS_KEY, 0, -1)
        if len(infected_list) != previous_num_users:
            logging.info(f"syncing {len(infected_list)} users over")
            for user_data in infected_list:
                config.REDIS_CLIENT.rpush(config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY, user_data)
            # save this
            previous_num_users = len(infected_list)
        time.sleep(1)


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
    logging.info(f"sleeping for {sleep_time} seconds until next UTC midnight")
    time.sleep(sleep_time)


# delete the day distribution list
def purge_infected_users_list():
    logging.info(f"purging distribution list")
    config.REDIS_CLIENT.delete(config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY)


# migrate each user into the distribution list
# [todo] do not delete the list as that could lose data if this function fails
# instead, archive the key for a few days before deleting for better resiliency
def migrate_all_infected_user_reports():
    logging.info("migrating all infected user reports")
    pipeline = config.REDIS_CLIENT.pipeline()
    pipeline.lrange(config.REDIS_LATEST_INFECTED_USERS_KEY, 0, -1)
    pipeline.delete(config.REDIS_LATEST_INFECTED_USERS_KEY)
    responses = pipeline.execute()
    user_list = responses[0]

    # pipeline send the users
    pipeline = config.REDIS_CLIENT.pipeline()
    for user_data in user_list:
        pipeline.rpush(config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY, user_data)
    pipeline.execute()
