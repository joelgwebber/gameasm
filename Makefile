GULP := node ./node_modules/gulp/bin/gulp.js

# Builds the js client.
.PHONY: js
js:
	$(GULP)

.PHONY: dev
dev:
	$(GULP) webpack-dev &
	python -m SimpleHTTPServer 2112

.PHONY: run
run: js
	python -m SimpleHTTPServer 2112

all: js

