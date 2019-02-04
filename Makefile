php:
	cd bref/runtime/php && $(MAKE) compiler
	docker build -f ${PWD}/php.Dockerfile -t bref/runtime/php-full-72:latest $(shell ${PWD}/bref/runtime/php/helpers/docker_args.php php72) .
	docker build -f ${PWD}/php.Dockerfile -t bref/runtime/php-full-73:latest $(shell ${PWD}/bref/runtime/php/helpers/docker_args.php php73) .

extensions:
	docker build -t stechstudio/bref/extensions .
