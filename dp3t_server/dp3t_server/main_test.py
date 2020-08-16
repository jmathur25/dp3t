import unittest
from unittest import mock
import datetime
import json
import fakeredis

import config
config.IS_TEST = True
import main
from db import db

class ServerTest(unittest.TestCase):
    main.app.testing = True
    client = main.app.test_client()

    @mock.patch("config.REDIS_CLIENT", fakeredis.FakeStrictRedis())
    def test_report_infected_user(self):
        post_data = {'user_id': 'a'*64, 'date': '2020-06-25'}

        # post
        resp = ServerTest.client.post("/report_infected_user", data=json.dumps(post_data))
        self.assertEqual(resp.status_code, 200)

        infected_users = config.REDIS_CLIENT.lrange(config.REDIS_LATEST_INFECTED_USERS_KEY, 0, -1)
        for i in range(len(infected_users)):
            infected_users[i] = json.loads(infected_users[i])

        self.assertEqual(infected_users, [post_data])

    
    @mock.patch("config.REDIS_CLIENT", fakeredis.FakeStrictRedis())
    def test_infected_users_list(self):
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

        user_string_list = []
        for user in user_list:
            user_str = json.dumps(user)
            user_string_list.append(user_str)
            config.REDIS_CLIENT.rpush(config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY, user_str)

        # get
        resp = ServerTest.client.get("/infected_users_list")
        data = json.loads(resp.get_data())
        self.assertEqual(set(data), set(user_string_list))


    @mock.patch("config.REDIS_CLIENT", fakeredis.FakeStrictRedis())
    def test_end_to_end(self):
        post_data = {'user_id': 'a'*64, 'date': '2020-06-25'}
        data_str = json.dumps(post_data)

        # post
        resp = ServerTest.client.post("/report_infected_user", data=data_str)
        self.assertEqual(resp.status_code, 200)

        # migrate
        db.migrate_all_infected_user_reports()

        # get
        resp = ServerTest.client.get("/infected_users_list")
        self.assertEqual(resp.status_code, 200)
        data = json.loads(resp.get_data())
        self.assertEqual(set(data), set([data_str]))

