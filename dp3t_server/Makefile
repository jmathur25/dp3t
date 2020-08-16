FILE?=*_test.py

VENV_NAME?=.dp3t_server
PYTHON=${VENV_NAME}/bin/python3

DOCKER_USERNAME?=jmather
CONTAINER_NAME?=dp3t-server
CONTAINER_VERSION?=1.0

NAMESPACE?=dp3t
DEPLOYMENT_NAME?=dp3t-server

PURPLE_COLOR='\033[1;34m'
NO_COLOR='\033[0m'

.PHONY: setup
setup:
	python3 -m venv ${VENV_NAME}
	${PYTHON} -m pip install -r dp3t_server/requirements.txt

.PHONY: local
local:
	docker-compose build
	docker-compose up

# makes docker image and pushes to public registry
.PHONY: docker-image
docker-image:
	docker build -t ${CONTAINER_NAME} -f dp3t_server/prod.Dockerfile .
	docker tag ${CONTAINER_NAME} ${DOCKER_USERNAME}/${CONTAINER_NAME}:${CONTAINER_VERSION}
	docker push ${DOCKER_USERNAME}/${CONTAINER_NAME}:${CONTAINER_VERSION}

.PHONY: deploy
deploy:
	@echo "${PURPLE_COLOR} If you have made changes to the server code, run:"
	@echo "${PURPLE_COLOR} make docker-image${NO_COLOR}"
	# deploy
	kubectl apply -f k8s-deploy
	# expose with load balancer
	kubectl -n ${NAMESPACE} expose deployment ${DEPLOYMENT_NAME} --name=${DEPLOYMENT_NAME}-lb --type=LoadBalancer --port 80 --target-port 80
	# autoscaling
	kubectl -n ${NAMESPACE} autoscale deployment ${DEPLOYMENT_NAME} --cpu-percent=80 --min=1 --max=5

.PHONY: teardown
teardown:
	kubectl -n ${NAMESPACE} delete -f k8s-deploy
	kubectl -n ${NAMESPACE} delete service ${DEPLOYMENT_NAME}-lb
	kubectl -n ${NAMESPACE} delete hpa ${DEPLOYMENT_NAME}

.PHONY: test
test: unittest

.PHONY: unittest
unittest:
	${PYTHON} -m unittest discover -v -s ./dp3t_server -p $(FILE)
