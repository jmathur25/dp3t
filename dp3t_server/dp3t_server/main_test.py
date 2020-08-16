import unittest
from unittest import mock
import json
import fakeredis

import config
config.IS_TEST = True
import main


class DbTest(unittest.TestCase):
    @mock.patch("config.REDIS_CLIENT", fakeredis.FakeStrictRedis())
    # @mock.patch("flask.request")
    def test_report_infected_user(self):
        # client = get_and_close_test_client()
        main.app.testing = True
        client = main.app.test_client()
        post_data = {'user_id': 'a'*64, 'date': '2020-06-25'}

        # post
        resp = client.post("/report_infected_user", data=json.dumps(post_data))
        self.assertEqual(resp.status_code, 200)

        infected_users = config.REDIS_CLIENT.lrange(config.REDIS_LATEST_INFECTED_USERS_KEY, 0, -1)
        for i in range(len(infected_users)):
            infected_users[i] = json.loads(infected_users[i])

        self.assertEqual(infected_users, [post_data])


