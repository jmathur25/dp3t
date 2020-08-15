FROM tiangolo/meinheld-gunicorn-flask:python3.7

RUN mkdir -p /build

COPY dp3t_server /app
COPY requirements.txt /build

RUN pip install -r /build/requirements.txt