# this file defines all server endpoints

import json
import flask
import logging
import datetime

from shared import (
    REDIS_CLIENT,
    REDIS_DISTRIBUTE_INFECTED_USERS_KEY,
    REDIS_LATEST_INFECTED_USERS_KEY,
    MAX_DAY_STORAGE,
    ID_LENGTH,
    DATE_FORMAT
)
import db

APPLICATION = flask.Flask(__name__)


@APPLICATION.route('/', methods=['GET'])
def home():
    return "App home page :)"


@APPLICATION.route('/infected_users_list/<year>/<month>/<day>', methods=['GET'])
def infected_users(year, month, day):
    key = REDIS_DISTRIBUTE_INFECTED_USERS_KEY.format(year, month, day)
    user_list = REDIS_CLIENT.lrange(key, 0, -1)
    for i in range(len(user_list)):
        # convert byte string to string
        user_list[i] = str(user_list[i])
    return json.dumps(user_list)


@APPLICATION.route('/report_infected_user', methods=['POST'])
def report_infected_user():
    data = None
    try:
        data = json.loads(flask.request.get_data())
    except Exception:
        logging.error("Error could not parse JSON", exc_info=True)
        resp = flask.make_response("Error: could not parse JSON", 400)
        return resp
    
    # verify data
    for k in ['user_id', 'date']:
        if k not in data:
            resp = flask.make_response(f"Error: {k} not in JSON", 400)
            return resp
    user_id = data['user_id']
    if len(user_id) != ID_LENGTH:
        resp = flask.make_response("Error: user_id should have length 26", 400)
        return resp
    date_str = data['date']
    try:
        # see if we can parse date
        datetime.datetime.strptime(date_str, DATE_FORMAT)
    except:
        resp = flask.make_response("Error: date was not expected format of YYYY/MM/DD", 400)
        return resp

    # insert into redis
    json_data = json.dumps(
        {
            "user_id": user_id,
            "date": date_str,

        }
    )
    if REDIS_CLIENT.rpush(REDIS_LATEST_INFECTED_USERS_KEY, json_data) != 1:
        resp = flask.make_response("Error: failed to save provided data", 500)
        return resp

    return flask.make_response("", 202)
    

# run the application.
if __name__ == "__main__":
    APPLICATION.debug = True
    APPLICATION.run(host="0.0.0.0", threaded=True)
    db.setup_and_run_maintenance()
