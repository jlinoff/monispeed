#!/usr/bin/env python3
'''
Validate basic selenium chrome setup.
'''
import datetime
import inspect
import os
import sys
import time

from selenium.webdriver.chrome.service import Service
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import WebDriverException
import chromedriver_autoinstaller

HEADLESS = int(os.getenv('HEADLESS', '1'))  # headless flag
SLEEP = int(os.getenv('SLEEP', '1'))  # sleep interval
URL = os.getenv('URL', 'https://fast.com') # for testing
VERBOSE = int(os.getenv('VERBOSE', '0'))


def date_iso_8601_format(dts: datetime.datetime) -> str:
    '''Convert to 8601 format.
    Same format as date  --iso-8601=second.
    '''
    obj = dts.astimezone().tzinfo.utcoffset(dts.astimezone()) # type: ignore
    secs = obj.seconds # type: ignore
    days = obj.days # type: ignore
    if days < 0 :
        secs_per_day = 24 *  3600 # 8400
        offset = time.strftime('-%H:%M',time.gmtime(secs_per_day-secs))
    else:
        offset = time.strftime('+%H:%M',time.gmtime(secs))
    tstr = dts.isoformat(timespec='seconds') + offset
    return tstr


def info(msg: str, level: int = 1) -> None:
    '''
    Output an info message.
    '''
    lnum = inspect.stack()[level].lineno
    print(f'\x1b[34;1mINFO:{lnum}: {msg}\x1b[0m')


def err(msg: str, level: int = 1, abort: bool = True) -> None:
    '''
    Output an info message.
    '''
    lnum = inspect.stack()[level].lineno
    print(f'\x1b[31;1mERROR:{lnum}: {msg}\x1b[0m')
    if abort:
        sys.exit(1)


def install_chromedriver():
    '''setup chromedriver'''
    if VERBOSE:
        info(f'install current chromedriver')
    chromedriver_autoinstaller.install()
    driver = webdriver.Chrome()
    driver.get("http://www.python.org")
    assert "Python" in driver.title


def main():
    'main'
    chromedriver_autoinstaller.install()
    driver = webdriver.Chrome()
    options = webdriver.ChromeOptions()
    if HEADLESS:
        if VERBOSE:
            info('headless mode')
        options.add_argument("--headless")
    driver = webdriver.Chrome(options=options)
    try:
        if VERBOSE:
            info(f'navigating to {URL}')
        driver.get(URL)
        if VERBOSE:
            info('waiting...')
        start = time.time()
        interval = SLEEP
        while True:
            if VERBOSE > 1:
                info('checking for completion...')
            time.sleep(interval)
            element = driver.find_element(By.ID, "show-more-details-link")
            if element.text:
                break
        total = time.time() - start
        if VERBOSE:
            info(f'capture complete after {total:.1f} seconds')
        speed_value = driver.find_element(By.ID, "speed-value")
        speed_units = driver.find_element(By.ID, "speed-units")
        dts = date_iso_8601_format(datetime.datetime.now())
        if VERBOSE:
            info(f'internet access speed: {dts} {speed_value.text} {speed_units.text} {total:.1f} seconds')
        print(f'speed,{dts},{speed_value.text},{speed_units.text},{total:.1f}')
    except KeyboardInterrupt:
        pass
    except WebDriverException as exc:
        err(f'{exc.msg}', abort=False)
    if VERBOSE:
        info('quit')
    driver.quit()
    if VERBOSE:
        info('done')

if __name__ == '__main__':
    main()
