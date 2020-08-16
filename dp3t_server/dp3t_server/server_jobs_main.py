import logging
from db import db


if __name__ == "__main__":
    logging.basicConfig(filename="/logs/server_jobs.log", level=logging.INFO)
    db.setup_and_run_maintenance()

