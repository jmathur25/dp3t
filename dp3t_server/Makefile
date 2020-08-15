FILE?=*_test.py

VENV_NAME?=.dp3t_server
PYTHON=${VENV_NAME}/bin/python3

CONTAINER_NAME?=dp3t-server

.PHONY: setup
setup:
	virtualenv ${VENV_NAME}
	${PYTHON} -m pip install -r requirements.txt

.PHONY: server
server:
	${PYTHON} dp3t_server/main.py

.PHONY: docker-container
docker-container:
	docker build -t ${CONTAINER_NAME} .
	docker run -d -p 5000:80 --name=${CONTAINER_NAME} ${CONTAINER_NAME}

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
