FILE?=*_test.py

.PHONY: setup
setup:
	virtualenv .dp3t-server
	pip install -r requirements.txt

.PHONY: test
test:
	@echo "========================="
	@echo "Running all tests"
	@echo "========================="
	python -m unittest discover -v -s ./ -p $(FILE)
