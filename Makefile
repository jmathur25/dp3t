
setup:
	virtualenv .dp3t-server
	pip install -r requirements.txt

develop:
	source .dp3t-server/bin/activate

undevelop:
	deactivate
 