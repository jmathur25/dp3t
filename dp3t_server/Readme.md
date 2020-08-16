
If running for the first time, run:
```
make setup
```

To run locally, run:
```
source .dp3t_server/bin/activate
```

You can exit by running:
```
deactivate
```

# Deployment
## Setup
The GKE is a nice, low-cost way to deploy with Kubernetes. Helpful links:
- https://cloud.google.com/kubernetes-engine/docs/tutorials/hello-app

1. Install the gcloud CLI and the kubectl binary.
2. Make the GKE project in the console. https://cloud.google.com/kubernetes-engine/pricing 
says that a single zone project can be free.
3. Hit the "Conenct" tab in the top bar. Run the command that shows up in terminal. This adds GKE as a kubernetes endpoint.
4. In Docker Desktop, you should see GKE as a context. Enable it if you want to deploy to GKE.

## Deploy
If you are doing this for the first time, run:
```
kubectl create namespace dp3t
```

Then:
```
make deploy
```
