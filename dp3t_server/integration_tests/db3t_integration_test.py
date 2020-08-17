'''
Runs integration tests for the server
'''

import unittest
import requests
import json
import time
import datetime

URL = 'http://localhost:5000'

class ServerIntegrationTest(unittest.TestCase):
    def test_end_to_end(self):
        data = {'user_id': 'a' * 64, 'date': datetime.datetime.utcnow().strftime("%Y-%m-%d")}
        data_str = json.dumps(data)
        resp = requests.post(f'{URL}/report_infected_user', data=data_str)
        self.assertEqual(resp.status_code, 200)

        # let the data sync
        time.sleep(2)

        resp = requests.get(f'{URL}/infected_users_list')
        print(resp.content)
        self.assertEqual(resp.status_code, 200)
        data_response = json.loads(resp.content)
        self.assertEqual(set(data_response), set([data_str]))



