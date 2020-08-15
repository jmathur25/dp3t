FILE?=*_test.py

VENV_NAME?=.dp3t_server
PYTHON=${VENV_NAME}/bin/python3

DOCKER_USERNAME?=jmather
CONTAINER_NAME?=dp3t-server
CONTAINER_VERSION?=1.1

.PHONY: setup
setup:
	virtualenv ${VENV_NAME}
	${PYTHON} -m pip install -r dp3t_server/requirements.txt

.PHONY: local
local:
	docker-compose up

# deploy docker
.PHONY: docker-image
docker-image:
	docker build -t ${CONTAINER_NAME} -f Dockerfiles/prod.Dockerfile .
	docker tag ${CONTAINER_NAME} ${DOCKER_USERNAME}/${CONTAINER_NAME}-${CONTAINER_VERSION}
	docker push ${DOCKER_USERNAME}/${CONTAINER_NAME}-${CONTAINER_VERSION}

.PHONY: test
test:
	docker exec -it dp3t_server python -m unittest discover -v -s ./ -p $(FILE)

.PHONY: travis-ci-test
travis-ci-test:
	python -m unittest discover -v -s ./dp3t_server -p $(FILE)
