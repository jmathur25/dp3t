FILE?=*_test.py

VENV_NAME?=.dp3t_server
PYTHON=${VENV_NAME}/bin/python3

.PHONY: setup
setup:
	virtualenv ${VENV_NAME}
	${PYTHON} -m pip install -r requirements.txt

.PHONY: test
test:
	@echo "========================="
	@echo "Running all tests"
	@echo "========================="
	${PYTHON} -m unittest discover -v -s ./ -p $(FILE)

.PHONY: travis-ci-test
travis-ci-test:
	@echo "========================="
	@echo "Running all tests"
	@echo "========================="
	python -m unittest discover -v -s ./ -p $(FILE)