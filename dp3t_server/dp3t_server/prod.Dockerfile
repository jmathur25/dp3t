FROM tiangolo/meinheld-gunicorn-flask:python3.7

# Clone code
RUN mkdir -p /build
RUN git clone https://github.com/jmather625/dp3t /build/dp3t
RUN cp -r /build/dp3t/dp3t_server/dp3t_server/* /app

# Install dependencies
RUN pip install -r /build/dp3t/dp3t_server/dp3t_server/requirements.txt

# Make port 80 available for links and/or publish
EXPOSE 80
