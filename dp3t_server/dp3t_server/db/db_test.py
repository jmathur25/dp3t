import unittest
from unittest import mock
import datetime
from freezegun import freeze_time
import fakeredis
import json

import config
config.IS_TEST = True
from db import db

class DbTest(unittest.TestCase):
    @freeze_time('2020-06-25 02:05:33')
    @mock.patch("time.sleep")
    def test_sleep_until_utc_midnight(self, time_mock):
        # run function
        db.sleep_until_utc_midnight()

        expected_sleep_time = 78867
        time_mock.assert_called_once_with(expected_sleep_time)


    @freeze_time('2020-06-25 02:05:33')
    @mock.patch("config.REDIS_CLIENT", fakeredis.FakeStrictRedis())
    def test_purge_old_infected_users_list(self):
        config.REDIS_CLIENT.rpush(
            config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY,
            "a"*64,
            "b"*64,
        )

        # run function
        db.purge_infected_users_list()

        users = config.REDIS_CLIENT.lrange(config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY, 0, -1)
        self.assertEqual(users, [])

    
    @freeze_time('2020-06-25 02:05:33')
    @mock.patch("config.REDIS_CLIENT", fakeredis.FakeStrictRedis())
    def test_migrate_all_infected_user_reports(self):
        fakeuser1 = {
            "user_id": "a"*64,
            "date": "2020-06-25",
        }
        fakeuser2 = {
            "user_id": "b"*64,
            "date": "2020-06-25",
        }
        fakeuser3 = {
            "user_id": "c"*64,
            "date": "2020-06-24",
        }
        user_list = [fakeuser1, fakeuser2, fakeuser3]

        # these people have reported themselves as sick
        user_string_list = []
        for user in user_list:
            user_str = json.dumps(user)
            user_string_list.append(user_str)
            config.REDIS_CLIENT.rpush(config.REDIS_LATEST_INFECTED_USERS_KEY, user_str)

        # run command
        db.migrate_all_infected_user_reports()

        users = config.REDIS_CLIENT.lrange(config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY, 0, -1)
        for i in range(len(users)):
            users[i] = users[i].decode()
        self.assertEqual(set(users), set(user_string_list))
