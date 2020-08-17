'''
Run the following server jobs:

- sync over the reported infected users to the daily distribution list every 24h (at UTC midnight)
'''

import logging
from db import db


if __name__ == "__main__":
    logging.basicConfig(filename="/logs/server_jobs.log", level=logging.INFO)
    db.setup_and_run_maintenance()

