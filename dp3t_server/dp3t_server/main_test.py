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
        today = datetime.datetime(
            year=2020,
            month=6,
            day=25,
            hour=2,
            minute=5,
            second=33,
            tzinfo=datetime.timezone.utc,
        )
        yday = today + datetime.timedelta(days=-1)
        today_key = config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY.format(today.year, today.month, today.day)
        yday_key = config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY.format(yday.year, yday.month, yday.day)

        config.REDIS_CLIENT.rpush(
            today_key,
            "a"*64,
            "b"*64,
        )
        config.REDIS_CLIENT.rpush(
            yday_key,
            "c"*64,
            "d"*64,
        )

        # get
        resp = ServerTest.client.get("/infected_users_list/2020/6/23")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(json.loads(resp.get_data()), [])

        resp = ServerTest.client.get("/infected_users_list/2020/6/24")
        self.assertEqual(resp.status_code, 200)
        data = json.loads(resp.get_data())
        self.assertEqual(set(data), {'c'*64, 'd'*64})

        resp = ServerTest.client.get("/infected_users_list/2020/6/25")
        self.assertEqual(resp.status_code, 200)
        data = json.loads(resp.get_data())
        self.assertEqual(set(data), {'a'*64, 'b'*64})
