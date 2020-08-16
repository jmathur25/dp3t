FROM tiangolo/meinheld-gunicorn-flask:python3.7

# Install dependencies
RUN mkdir -p /build
RUN mkdir -p /logs
ADD requirements.txt /build/requirements.txt
RUN pip install -r /build/requirements.txt

# Copy our code from the current folder to /app inside the container
ADD . /app

# Make port 80 available for links and/or publish
EXPOSE 80

# the CMD is run by the source container from tiangolo
