''' this file defines all server endpoints '''

import json
import logging
import datetime
import flask

from db import db
import config

app = flask.Flask(__name__)


@app.route('/', methods=['GET'])
def home():
    return "App home page :)"


@app.route('/infected_users_list', methods=['GET'])
def infected_users_list():
    user_list = config.REDIS_CLIENT.lrange(config.REDIS_DISTRIBUTE_INFECTED_USERS_KEY, 0, -1)
    for i in range(len(user_list)):
        # convert byte string to string
        user_list[i] = user_list[i].decode()
    return json.dumps(user_list)


@app.route('/report_infected_user', methods=['POST'])
def report_infected_user():
    data = None
    try:
        data = json.loads(flask.request.get_data())
    except:
        logging.error("Error could not parse JSON", exc_info=True)
        resp = flask.make_response("Error: could not parse JSON", 400)
        return resp
    
    logging.info(f"DATA {data}")
    user_id = data['user_id']
    if len(user_id) != config.ID_LENGTH:
        msg = f"Error: user_id should have length {config.ID_LENGTH}"
        logging.info(msg)
        resp = flask.make_response(msg, 400)
        return resp
    date_str = data['date']
    try:
        # see if we can parse date
        datetime.datetime.strptime(date_str, config.DATE_FORMAT)
    except:
        msg = f"Error: date was not expected format of {config.DATE_FORMAT}"
        logging.info(msg)
        resp = flask.make_response(msg, 400)
        return resp

    # insert into redis
    json_data = json.dumps(
        {
            "user_id": user_id,
            "date": date_str,

        }
    )
    ins_redis = config.REDIS_CLIENT.rpush(config.REDIS_LATEST_INFECTED_USERS_KEY, json_data)
    if type(ins_redis) != int:
        logging.info(f"failed to insert to redis with response {ins_redis}")
        resp = flask.make_response("Server Error: failed to save provided data", 500)
        return resp

    return flask.make_response("", 200)


def setup():
    logging.basicConfig(level=logging.INFO)
    if not config.REDIS_CLIENT.ping():
        logging.fatal("error: could not ping redis")
    logging.info("--- SETUP SUCCESSFULLY ---")

setup()


# run the application.
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True, threaded=True)
