
all: config php extensions zip

config:
	php ${PWD}/config.php

php:
	cd bref/runtime/php && $(MAKE) compiler
	docker build -f ${PWD}/php.Dockerfile -t bref/runtime/php-full-73:latest $(shell ${PWD}/bref/runtime/php/helpers/docker_args.php php73) .

extensions:
	docker build -t stechstudio/bref/extensions .

zip:
	$(eval DOCKERID := $(shell docker create stechstudio/bref/extensions))
	docker cp $(DOCKERID):/tmp/sts-php-73.zip sts-php-73.zip
	docker rm -v  $(DOCKERID)

publish:
	aws lambda publish-layer-version --region us-east-1 --layer-name sts-bref-extensions --description "Extensions and Tools compiled to run as a layer on bref-php" --license-info MIT --zip-file fileb://sts-php-73.zip --compatible-runtimes provided --output text --query Version
