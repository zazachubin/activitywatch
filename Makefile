# =====================================
# Makefile for the ActivityWatch bundle
# =====================================
#
# [GUIDE] How to install from source:
#  - https://activitywatch.readthedocs.io/en/latest/installing-from-source.html
#
# We recommend creating and activating a Python virtualenv before building.
# Instructions on how to do this can be found in the guide linked above.

# These targets should always rerun
.PHONY: build install test clean clean_all

SHELL := /usr/bin/env bash

# The `build` target
# ------------------
#
# What it does:
#  - Installs all the Python modules
#  - Builds the web UI and bundles it with aw-server
#
# Arguments:
#  - `DEV=true` makes all `pip install` commands run with `--editable`.
#    Removes the need to reinstall Python packages when working on them.
#
# Tips:
#  - Set the environment variable `PIP_USER=true` for pip to install all Python
#    packages as user packages (same as `pip install --user <pkg>`). This makes
#    it possible to install without using a virtualenv (or root).
build:
	if [ -e "aw-core/.git" ]; then \
		echo "Submodules seem to already be initialized, continuing..."; \
	else \
		git submodule update --init --recursive; \
	fi
#
	make --directory=aw-core build DEV=$(DEV)
	make --directory=aw-client build DEV=$(DEV)
	make --directory=aw-server build DEV=$(DEV)
	make --directory=aw-watcher-afk build DEV=$(DEV)
	make --directory=aw-watcher-window build DEV=$(DEV)
	make --directory=aw-qt build DEV=$(DEV)
#   The below is needed due to: https://github.com/ActivityWatch/activitywatch/issues/173
	make --directory=aw-client build DEV=$(DEV)
	make --directory=aw-core build DEV=$(DEV)
#
	python3 -c "import aw_server; print(aw_server.__version__)"


# Install
# -------
#
# Installs things like desktop/menu shortcuts.
# Might in the future configure autostart on the system.
install:
	make --directory=aw-qt install
# Installation is already happening in the `make build` step currently.
# We might want to change this.
# We should also add some option to install as user (pip3 install --user)

# Update
# ------
#
# Pulls the latest version, updates all the submodules, then runs `make build`.
update:
	git pull
	git submodule update --init --recursive
	make build

# Update (bleeding edge)
# ------
#
# Pulls the latest version, updates all the submodules, then runs `make build`.
update-edge:
	git pull
	git submodule update --init --recursive
	git submodule foreach -v --recursive "echo 'test' $$(pwd); git checkout master; git pull origin master"
	make build

create-pipenv:
	# pipenv --python 3.6
	#pipenv install --skip-lock -r aw-core/requirements.txt
	#pipenv install --skip-lock -r aw-core/requirements-dev.txt --dev
	#pipenv install --skip-lock -r aw-server/requirements.txt
	#pipenv install --skip-lock -r aw-client/requirements.txt
	#pipenv install --skip-lock -r aw-watcher-afk/requirements.txt
	pipenv install --skip-lock -r aw-watcher-window/requirements.txt
	pipenv install --skip-lock -r aw-qt/requirements.txt



lint:
	pylint -E \
		aw-core/aw_core/ \
		aw-core/aw_datastore/ \
		aw-core/aw_transform/ \
		aw-core/aw_analysis/ \
		aw-client/aw_client/ \
		aw-server/aw_server/ \
		aw-watcher-window/aw_watcher_window/ \
		aw-watcher-afk/aw_watcher_afk/ \
		aw-qt/aw_qt/

# Uninstall
# ---------
#
# Uninstalls all the Python modules.
uninstall:
	modules=$$(pip3 list --format=legacy | grep 'aw-' | grep -o '^aw-[^ ]*'); \
	for module in $$modules; do \
		echo "Uninstalling $$module"; \
		pip3 uninstall -y $$module; \
	done

test:
	make --directory=aw-core test
	make --directory=aw-client test
	make --directory=aw-server test
	make --directory=aw-qt test

test-integration:
	# TODO: Move "integration tests" to aw-client
	# FIXME: For whatever reason the script stalls on Appveyor
	#        Example: https://ci.appveyor.com/project/ErikBjare/activitywatch/build/1.0.167/job/k1ulexsc5ar5uv4v
	pytest ./scripts/tests/integration_tests.py ./aw-server/tests/ -v

package:
	mkdir -p dist/activitywatch
#
	make --directory=aw-watcher-afk package
	cp -r aw-watcher-afk/dist/aw-watcher-afk/. dist/activitywatch
#
	make --directory=aw-watcher-window package
	cp -r aw-watcher-window/dist/aw-watcher-window/. dist/activitywatch
#
	make --directory=aw-server package
	cp -r aw-server/dist/aw-server/. dist/activitywatch
#
	make --directory=aw-qt package
	cp -r aw-qt/dist/aw-qt/. dist/activitywatch
# Remove problem-causing binaries, see https://github.com/ActivityWatch/activitywatch/issues/161
	rm -f dist/activitywatch/libdrm.so.2
# Remove unecessary files
	rm -rf dist/activitywatch/pytz
# Builds zips and setups
	bash scripts/package/package-all.sh

clean:
	rm -rf build dist

# Clean all subprojects
clean_all: clean
	make --directory=aw-client clean
	make --directory=aw-core clean
	make --directory=aw-qt clean
	make --directory=aw-server clean
	make --directory=aw-watcher-afk clean
	make --directory=aw-watcher-window clean
