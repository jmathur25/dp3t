FILE?=*_test.py

VENV_NAME?=.dp3t_server
PYTHON=${VENV_NAME}/bin/python3

DOCKER_USERNAME?=jmather
CONTAINER_NAME?=dp3t-server
CONTAINER_VERSION?=1.2

YELLOW_COLOR='\033[1;34m'
NO_COLOR='\033[0m'

.PHONY: setup
setup:
	virtualenv ${VENV_NAME}
	${PYTHON} -m pip install -r dp3t_server/requirements.txt

.PHONY: local
local:
	docker-compose up

# makes docker image and pushes to public registry
.PHONY: docker-image
docker-image:
	docker build -t ${CONTAINER_NAME} -f Dockerfiles/prod.Dockerfile .
	docker tag ${CONTAINER_NAME} ${DOCKER_USERNAME}/${CONTAINER_NAME}:${CONTAINER_VERSION}
	docker push ${DOCKER_USERNAME}/${CONTAINER_NAME}:${CONTAINER_VERSION}

.PHONY: deploy
deploy:
	@echo "${YELLOW_COLOR} If you have made changes to the server code, run:"
	@echo "${YELLOW_COLOR} make docker-image"
	# deploy
	kubectl apply -f k8s-deploy
	# expose with load balancer
	kubectl -n dp3t expose deployment dp3t-server --name=dp3t-server-lb --type=LoadBalancer --port 80 --target-port 80
	# autoscaling
	kubectl -n dp3t autoscale deployment dp3t-server --cpu-percent=80 --min=1 --max=5

.PHONY: teardown
teardown:
	kubectl -n dp3t delete -f k8s-deploy
	kubectl -n dp3t delete service dp3t-server-lb

.PHONY: test
test:
	docker exec -it dp3t_server python -m unittest discover -v -s ./ -p $(FILE)

.PHONY: travis-ci-test
travis-ci-test:
	python -m unittest discover -v -s ./dp3t_server -p $(FILE)
