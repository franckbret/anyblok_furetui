.PHONY: clean clean-build clean-pyc lint test setup help
.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

setup: ## install python project dependencies
	pip install --upgrade pip wheel
	pip install --upgrade -r requirements.txt
	pip install -e .

setup-tests: ## install python project dependencies for tests
	pip install --upgrade pip wheel
	pip install --upgrade -r requirements.test.txt
	pip install -e .
	anyblok_createdb -c app.test.cfg || anyblok_updatedb -c app.test.cfg

setup-dev: ## install python project dependencies for development
	pip install --upgrade pip wheel
	pip install --upgrade -r requirements.dev.txt
	pip install -e .
	anyblok_createdb -c app.dev.cfg || anyblok_updatedb -c app.dev.cfg
	## install nodejs / npm
	nodeenv -p
	npm i -g npm
	npm --prefix furetui_vue/ install

run-dev: ## launch pyramid development server
	anyblok_pyramid -c app.dev.cfg --wsgi-host 0.0.0.0

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

lint: ## check style with flake8
	flake8 anyblok_furetui

test: ## run anyblok nose tests
	anyblok_nose -c app.test.cfg -- -v -s anyblok_furetui

documentation: ## generate documentation
	anyblok_doc -c app.test.cfg --doc-format RST --doc-output doc/source/apidoc.rst
	make -C doc/ html

run-dev-npm: ## launch npm development server with hot reload
	npm --prefix furetui_vue/ update
	npm --prefix furetui_vue/ run dev

build-assets: ## build js and scss assets for production
	npm --prefix furetui_vue/ update
	npm --prefix furetui_vue/ run build
	cp -rf furetui_vue/dist/furet-ui anyblok_furetui/furetui_api/static
	cp -f furetui_vue/dist/index.html anyblok_furetui/furetui_api/static/index.html
