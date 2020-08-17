# Overview
DP3T Server is a minimal backend server that implements the DP3T protocol. Its functionalities are simple:
- expose an endpoint to report yourself as having been infected
- expose an endpoint to get the latest infected users (a daily distribution list)

It is implemented using Flask and redis. In production, the server runs as a gunicorn server.

# Run Locally

If running for the first time, run:
```
make setup
```

To run locally, run:
```
make local
```

This setups up two docker containers, one for `dp3t_server` and the other for `redis`.
The `dp3t_server` container (called `dp3t_server_local`) is a volume mount to the `dp3t_server` folder, 
meaning if you change code in that folder it will reflect in the container. The local server is a Flask server, so Flask's 
auto restart upon detecting file changes applies despite being run in a Docker container.

You can also explicitly run the flask server by running:
```
source .dp3t_server/bin/activate
cd dp3t_server
python main.py
```
Note that this will crash because `redis` will not be available. You'll need to separately make that available.

There are existing unit tests and integration tests. Run them with:
```
make test
```

# Deployment
We use Kubernetes and Google Kubernetes Engine (GKE) to deploy the server. GKE is a nice, low-cost way to deploy with Kubernetes. 
Helpful intro links: https://cloud.google.com/kubernetes-engine/docs/tutorials/hello-app.

## Setup
Steps to setup deployment:

1. Install the `gcloud` CLI and the `kubectl` binary.
2. Make the GKE project in the console. https://cloud.google.com/kubernetes-engine/pricing 
says that a single zone project can be free.
3. Hit the "Connect" tab in the top bar. Run the command that shows up in terminal. This adds GKE as a kubernetes endpoint.
4. In Docker Desktop, you should see GKE as a context. When you want to deploy to GKE, enable that context.

## Deploy
Docker provides a local Kubernetes engine that you can use to test deployment. This feature is awesome because
you can use the exact same commands for deployment but test it out locally first. This differs from developing locally
because local development can use the local context, whereas deployment assumes no context. Check out the
differences between `dp3t_server/prod.Dockerfile` and `dp3t_server/local.Dockerfile`.

<strong>
The following instructions can be run both on the local kubernetes docker context and the publicly available GKE context.
</strong>

If you are doing this for the first time, run:
```
kubectl create namespace dp3t
```

Then:
```
make deploy
```

To access the deployed service, we need to load balancer's external IP. Run the following command to see it:
```
kubectl -n dp3t get svc
```
On local, this will just be `localhost:80`.
On prod, it might take a few seconds for GKE to give you an external IP. When it is available, run `curl http://<external ip>:<external port>`. The response should be "App home page :)". If so, congrats you have deployed successfully using the awesomeness that is Docker and Kubernetes :).

To end the deployment, run:
```
make teardown
```
