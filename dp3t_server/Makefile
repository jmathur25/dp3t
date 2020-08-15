FILE?=*_test.py

VENV_NAME?=.dp3t_server
PYTHON=${VENV_NAME}/bin/python3

DOCKER_USERNAME?=jmather
CONTAINER_NAME?=dp3t-server
CONTAINER_VERSION?=1.1

.PHONY: setup
setup:
	virtualenv ${VENV_NAME}
	${PYTHON} -m pip install -r requirements.txt

.PHONY: server
server:
	${PYTHON} dp3t_server/main.py

# --- deploy docker ---
.PHONY: docker-container
docker-container:
	docker build -t ${CONTAINER_NAME} -f deploy/Dockerfile .

.PHONY: docker-container-push
docker-container-push:
	docker tag ${CONTAINER_NAME} ${DOCKER_USERNAME}/${CONTAINER_NAME}-${CONTAINER_VERSION}
	docker ${DOCKER_USERNAME}/${CONTAINER_NAME}-${CONTAINER_VERSION}

.PHONY deploy
deploy:
	kubectl apply -f deploy/deploy.yaml
# ------

# --- test deploy docker ---
.PHONY: docker-container-test
docker-container-test:
	docker build -t ${CONTAINER_NAME}-test -f deploy_test/Dockerfile .

.PHONY: run-container-test
run-container-test:
	docker run -d -p 5000:80 --name=${CONTAINER_NAME}-test ${CONTAINER_NAME}-test

.PHONY: rm-container-test
rm-container-test:
	docker container stop ${CONTAINER_NAME}-test
	docker container rm ${CONTAINER_NAME}-test
# ------

.PHONY: test
test:
	@echo "========================="
	@echo "Running all tests"
	@echo "========================="
	${PYTHON} -m unittest discover -v -s ./dp3t_server -p $(FILE)

.PHONY: travis-ci-test
travis-ci-test:
	@echo "========================="
	@echo "Running all tests"
	@echo "========================="
	python -m unittest discover -v -s ./dp3t_server -p $(FILE)
