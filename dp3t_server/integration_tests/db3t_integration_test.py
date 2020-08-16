'''
Runs integration tests for the server
'''

import unittest
import requests
import json
import time


class ServerIntegrationTest(unittest.TestCase):
    def test_end_to_end(self):
        data = {'user_id': 'a' * 64, 'date': '2020-08-15'}
        data_str = json.dumps(data)
        resp = requests.post('http://0.0.0.0:5000/report_infected_user', data=data_str)
        self.assertEqual(resp.status_code, 200)

        # let the data sync
        time.sleep(2)

        resp = requests.get('http://0.0.0.0:5000/infected_users_list')
        self.assertEqual(resp.status_code, 200)
        data_response = json.loads(resp.content)
        self.assertEqual(set(data_response), set([data_str]))



