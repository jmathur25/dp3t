import unittest
from unittest import mock
import datetime

from freezegun import freeze_time

from db import db

class DbTest(unittest.TestCase):

    @freeze_time('2020-06-25 02:05:33')
    @mock.patch("time.sleep")
    def test_sleep_until_utc_midnight(self, time_mock):
        # run function
        db.sleep_until_utc_midnight()

        expected_sleep_time = 78867
        time_mock.assert_called_once_with(expected_sleep_time)


