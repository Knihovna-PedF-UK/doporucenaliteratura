import os
from os import path
import sys
import time

from selenium import webdriver
from bs4 import BeautifulSoup
from urllib import parse

url = sys.argv[1]
output_dir = sys.argv[2]

def process_page(browser, mainurl, link):
    newurl = parse.urljoin(mainurl, link)
    # name of department is in the "kod" url param. save it under this name in the 
    # output directory
    params = parse.parse_qs(parse.urlparse(newurl).query)
    kod = params.get('kod')[0]
    output_file = os.path.join(output_dir+ "/", kod+".html")
    if path.exists(output_file):
        # don't overwrite existing files 
        print("File exits: " + output_file)
        return False
    print("Saving file: " + output_file)
    f = open(output_file, "w")
    browser.get(newurl)
    f.write(browser.page_source)
    f.close()
    return True



try:
    fireFoxOptions = webdriver.FirefoxOptions()
    fireFoxOptions.headless =  True
    browser = webdriver.Firefox(options=fireFoxOptions)
    browser.get(url)
    mainpage = browser.page_source
    maindom = BeautifulSoup(mainpage, 'html.parser')
    urls = {}
    for link in maindom.select(".tab1 td a"):
        # we want unique links. each link appears twice on the page, so 
        # we need to use only the first one
        current_href = link.get('href')
        if urls.get( current_href ) != True:
            status = process_page(browser, url, current_href)
            if status==True:
                # we don't want to make DOS attack on SIS
                time.sleep(15)
        urls[current_href] = True

finally:
    try:
        brower.close()
    except:
        pass
