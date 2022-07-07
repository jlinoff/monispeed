# Makefile for monispeed.
SHELL       ?= 'bash'
PYTHON_PATH ?= /usr/local/opt/python@3.10/bin/python3
REQUIRED    := ./monispeed.sh ./plot-speed.gp ./chrome_fast.py

# Macros
define hdr
        @printf '\033[35;1m\n'
        @printf '=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n'
        @printf '=-=-= Target: %s %s\n' "$1"
        @printf '=-=-= Date: %s %s\n' "$(shell date)"
        @printf '=-=-= Directory: %s %s\n' "$$(pwd)"
        @printf '=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
        @printf '\033[0m\n'
endef

.PHONY: interval
interval: setup | $(REQUIRED)  ## Make a custom interval report. Must set START and STOP times. Example: make interval START=13:00 STOP=17:00
	$(call hdr,"$@-$(START)-to-$(STOP)")
	@BASE="monispeed-$(START)-to-$(STOP)" && \
	CSV="$$BASE-$@.csv" && \
	LOG="$$BASE-$@.log" && \
	VERBOSE=2 START=$(START) STOP=$(STOP) CSV="$$CSV" \
		./monispeed.sh 2>&1 | tee -i -a "$$LOG" && \
	if [ -f "$$CSV" ] ; then ./plot-speed.gp "$$CSV" ; fi

.PHONY: hour
hour: setup | $(REQUIRED)  ## Make an hourly report starting at the beginning of the next hour and display plot when done.
	$(call hdr,"$@")
	@BASE="monispeed-$$(date -d '+1 hour' +%F)" && \
	CSV="$$BASE-$@.csv" && \
	LOG="$$BASE-$@.log" && \
	START=$$(date +'%Y-%m-%dT%H:%M:00' -d '+1 hour') && \
	VERBOSE=2 START="$$START" STOP='1 hour' CSV="$$CSV" \
		./monispeed.sh 2>&1 | tee -i -a "$$LOG" && \
	if [ -f "$$CSV" ] ; then ./plot-speed.gp "$$CSV" ; fi

.PHONY: hour-now
hour-now: setup | $(REQUIRED)  ## Make an hourly report starting now and display plot when done.
	$(call hdr,"$@")
	@BASE="monispeed-$$(date -d '+1 hour' +%F)" && \
	CSV="$$BASE-$@.csv" && \
	LOG="$$BASE-$@.log" && \
	VERBOSE=2 STOP='1 hour' CSV="$$CSV" \
		./monispeed.sh 2>&1 | tee -i -a "$$LOG" && \
	if [ -f "$$CSV" ] ; then ./plot-speed.gp "$$CSV" ; fi

.PHONY: day
day: setup | $(REQUIRED)  ## Make a daily report for the next full day and display plot when done.
	$(call hdr,"$@")
	@BASE="monispeed-$$(date -d '+1 $@' +%F)" && \
	LOG="$$BASE-$@.log" && \
	CSV="$$BASE-$@.csv" && \
	VERBOSE=2 START="23:59" STOP='1 day' CSV="$$CSV" \
	./monispeed.sh 2>&1 | tee -i -a "$$LOG"  && \
	if [ -f "$$CSV" ] ; then ./plot-speed.gp "$$CSV" ; fi

.PHONY: week
week: setup | $(REQUIRED)  ## Make a weekly report starting the next full day and display plot when done.
	$(call hdr,"$@")
	BASE="monispeed-$$(date -d '+1 day' +%F)" && \
	CSV="$$BASE-$@.csv" && \
	LOG="$$BASE-$@.log" && \
	VERBOSE=2 START="23:59" STOP='1 week' CSV="$$CSV" \
		./monispeed.sh 2>&1 | tee -i -a "$$LOG" && \
	if [ -f "$$CSV" ] ; then ./plot-speed.gp "$$CSV" ; fi

.PHONY: setup
setup: | $(REQUIRED)  ## Setup the selenium python environment
	$(call hdr,"$setup")
	shellcheck monispeed.sh
	if [ ! -d .venv ] ; then \
	  PIPENV_VENV_IN_PROJECT=1 pipenv install \
	    --python=/usr/local/opt/python@3.10/bin/python3 \
	    mypy pylint selenium chromedriver-autoinstaller ; \
	fi

.PHONY: help
help:  ## this help message
	$(call hdr,"$@")
	@printf "\n\033[35;1m%s\n" "Targets"
	@grep -E '^[ ]*[^:]*[ ]*:.*##' $(MAKEFILE_LIST) 2>/dev/null | \
		grep -E -v '^ *#' | \
	        grep -E -v "egrep|sort|sed|MAKEFILE" | \
		sed -e 's/: .*##/##/' -e 's/^[^:#]*://' | \
		column -t -s '##' | \
		sort -f | \
		sed -e 's@^@   @'
	@printf "\033[0m\n"
