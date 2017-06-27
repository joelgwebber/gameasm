# Builds the js client.
.PHONY: js
js:
	gulp

.PHONY: dev
dev:
	gulp webpack-dev &
	python -m SimpleHTTPServer 2112

.PHONY: run
run: js
	python -m SimpleHTTPServer 2112

all: js

