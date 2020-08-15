
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
eksctl create cluster \
--name dp3t-app-prod \
--version 1.17 \
--region us-east-1 \
--fargate
