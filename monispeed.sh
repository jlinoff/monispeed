#!/usr/bin/env bash
#
# monitor internet speed.
#
# Environment Variables
#   START=time    Start time, default: now.
#                 Set START='17:00' to start a 5:00pm
#                 Set START='23:59' to start a 11:59pm
#                 Set START='10 minutes' to start in 10 minutes.
#   STOP=cond     STOP condition. default: None (runs forever) or until ctrl-c is entered.
#                 Set STOP='1 minute' to stop after a minute.
#                 Set STOP='2 minutes' to stop after two minutes.
#                 Set STOP='1 day' to stop after a day.
#                 Set STOP='2 days' to stop after two days.
#                 Set STOP='1 week' to stop after a week.
#                 Set STOP='2 weeks' to stop after two weeks.
#   CSV           CSV data file, default (speed.csv)
#   GCB           Google chrome browser path,
#                 default: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
#   GCD           Google chrome driver path, default: wd/chromedriver
#   HEADLESS      Headless flag, default: 1 (true)
#   INTERVAL      Test interval, default: 15m (900s)
#   URL           The fast URL, default: https://fast.com
#   VERBOSE       Verbosity flag (1-report status, 2-show CSV record)
: "${CSV=speed.csv}"
: "${GCB:=/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
: "${GCD:=wd/chromedriver}"
: "${HEADLESS:=1}"
: "${SLEEP:=1}"
: "${URL:=https://fast.com}"
: "${INTERVAL:=900}"
: "${STOP:=}"
: "${START:=}"
: "${VERBOSE:=0}"

# ================================================================
#
# functions
#
# ================================================================
# error message
function _err {
    printf '\x1b[31;1mERROR:%s: %s\x1b[0m\n' "$1" "$2"
}

# debug message
function _debug {
    printf '\x1b[35;1mDEBUG:%s: %s\x1b[0m\n' "$1" "$2"
}

# info message
function _info {
    printf '\x1b[34;1mINFO:%s: %s\x1b[0m\n' "$1" "$2"
}

# pause until boundary it reached
function pause_until {
    local INTERVAL
    local SEC  # avoid shellcheck warning
    # trim off the leading zero
    INTERVAL="$1"
    SEC=$(date +%s)
    local REM=$(( SEC % INTERVAL ))
    local SLEEP_TIME=$(( INTERVAL - REM ))
    if (( VERBOSE >= 4 )) ; then
        _debug "$LINENO" "$SEC % $INTERVAL => $REM : sleep $SLEEP_TIME"
    fi
    sleep $SLEEP_TIME
}

function settings {
    printf '\x1b[34;1m'
    cat <<EOF
Settings
   Start Date                  : $START_DATE
   Start Condition (START)     : "$START"
   Stop Date                   : $STOP_DATE
   Stop Condition (STOP)       : "$STOP"
   Capture Data File (CSV)     : $CSV
   Google Chrome Browser (GCB) : $GCB
   Google Chrome Driver (GCD)  : $GCD
   HEADLESS Flag               : $HEADLESS
   INTERVAL                    : $INTERVAL seconds
   SLEEP                       : $SLEEP seconds
   VERBOSE                     : $VERBOSE
   URL                         : $URL
EOF
    printf '\x1b[0m\n'
}

# ================================================================
#
# main
#
# ================================================================
# wait until the correct start condition
START_DATE=$(date --iso-8601=second)
STOP_DATE=''
STOP_DATE_SEC=0

if [ -n "$START" ] ; then
    START_DATE=$(date -d "$START" --iso-8601=second)
    START_DATE_SLEEP_SEC=$(( $(date -d "$START" +'%s') - $(date +'%s') ))
    if (( $(date -d "$START" +'%s') < $(date +'%s') )) ; then
        _info $LINENO "NOW    : $(date +'%s') $(date --iso-8601=second)"
        _info $LINENO "START  : $(date -d "$START" +'%s') $(date -d "$START" --iso-8601=second)"
        _err "$LINENO" "START earlier than NOW"
        exit 1
    fi
fi

if [ -n "$STOP" ] ; then
    if echo "$STOP" | grep -q -E '(-|:)' ; then
        # Handle explicit STOP dates like STOP=9:30
        STOP_DATE=$(date -d "$STOP" --iso-8601=second)
        STOP_DATE_SEC=$(date -d "$STOP" +'%s')
    else
        STOP_DATE=$(date -d "$START_DATE + $STOP" --iso-8601=second)
        STOP_DATE_SEC=$(date -d "$START_DATE + $STOP" +'%s')
    fi
    if [ -n "$START" ] ; then
        START_DATE_SEC=$(date -d "$START" +'%s')
        if (( STOP_DATE_SEC < START_DATE_SEC )) ; then
            _info "$LINENO" "STOP_DATE  : $STOP_DATE"
            _info "$LINENO" "START_DATE : $START_DATE"
            _info "$LINENO" "STOP_DATE_SEC  : $STOP_DATE_SEC"
            _info "$LINENO" "START_DATE_SEC : $START_DATE_SEC"
            _err "$LINENO" "STOP earlier than START"
            exit 1
        fi
    fi
fi

# display the settings
settings


# wait until stat condition is met
if (( START_DATE_SLEEP_SEC )) ; then
    if (( VERBOSE )) ; then
        _info "$LINENO" "waiting ($START_DATE_SLEEP_SEC) for start condition ($START): $START_DATE"
    fi
    sleep $START_DATE_SLEEP_SEC
fi

# wait until capture boundary to start
if (( VERBOSE )) ; then
    SLEEP_TIME=$(( INTERVAL - ($(date +%s) % INTERVAL) ))
    _info "$LINENO" "waiting for capture the $INTERVAL second interval boundary ($SLEEP_TIME seconds)"
fi
pause_until "$INTERVAL"

while true ; do
    DATE=$(date --iso-8601=second)
    DAY=$(date +%A)
    if (( VERBOSE >= 2 )) ; then
        _info "$LINENO" "querying internet speed on $DAY $DATE"
    fi
    VERBOSE=0 pipenv run ./chrome_fast.py >>"$CSV"
    if (( VERBOSE >= 2 )) ; then
        tail -1 "$CSV"
    fi
    if (( STOP_DATE_SEC > 0 )) ; then
        CURR_DATE_SEC=$(date '+%s')
        if (( CURR_DATE_SEC >= STOP_DATE_SEC )) ; then
            break
        fi
    fi
    pause_until "$INTERVAL"
    if (( STOP_DATE_SEC > 0 )) ; then
        CURR_DATE_SEC=$(date '+%s')
        if (( CURR_DATE_SEC >= STOP_DATE_SEC )) ; then
            break
        fi
    fi
done
if (( VERBOSE >= 1 )) ; then
    _info "$LINENO" "done"
fi
