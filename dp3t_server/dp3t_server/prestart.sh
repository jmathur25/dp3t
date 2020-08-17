#! /usr/bin/env bash

# the docker image I pull from runs prestart.sh if the file exists
# this runs the server jobs in the background

# Run custom Python script before starting
bash -c "python server_jobs_main.py &"
