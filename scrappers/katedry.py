import os
from os import path
import sys
import time

from selenium import webdriver
from bs4 import BeautifulSoup
from urllib import parse

katedry_file = sys.argv[1]
url = sys.argv[2]
output_dir = sys.argv[3]

# from https://matix.io/extract-text-from-webpage-using-beautifulsoup-and-python/
blacklist  =['script']

def get_literatura(source):
    dom = BeautifulSoup(source, 'html.parser')
    literatura = ""
    for tbl in dom.find_all("table"):
        # find table column with word "Literatura". Insane, I know.
        bolds = tbl.find("tr").find("td").select("b")
        if bolds:
            first = bolds[0].contents[0]
            if first == "Literatura":
                text = tbl.find_all(text=True)
                for t in text:
                    if t.parent.name not in blacklist:
                        literatura += '{} '.format(t)
    return literatura
    


def process_page(browser, mainurl, predmet):
    newurl = parse.urljoin(mainurl, predmet["url"])
    # name of department is in the "kod" url param. save it under this name in the 
    # output directory
    kod = predmet["kod"]
    output_file = os.path.join(output_dir+ "/", kod+".html")
    if path.exists(output_file):
        # don't overwrite existing files 
        print("File exits: " + output_file)
        return False
    print("Saving file: " + output_file)
    f = open(output_file, "w")
    browser.get(newurl)
    f.write(get_literatura(browser.page_source))
    f.close()
    return True

def get_predmet(tr):
    tds = row.find_all("td")
    if len(tds) > 5:
        enabled = tds[5].contents[0]
        if enabled == u"vyučován": # it seems we need to check explicitly for this string presence
            predmet = {}
            kod = tds[1].contents[0].contents[0] # get children's contents, for this reason we have contents twice
            predmet['kod'] = kod
            a = tds[0].find("a")
            predmet['url'] = a['href']
            print(predmet)
            return predmet
    return False



try:
    fireFoxOptions = webdriver.FirefoxOptions()
    fireFoxOptions.headless =  True
    browser = webdriver.Firefox(options=fireFoxOptions)
    # browser.get(url)
    # mainpage = browser.page_source
    f = open(katedry_file, "r")
    mainpage = f.read()
    f.close()
    maindom = BeautifulSoup(mainpage, 'html.parser')
    urls = {}
    for row in maindom.select(".tab1 tr"):
        predmet = get_predmet(row)
        if predmet:
            status = process_page(browser, url, predmet)
            if status==True:
                time.sleep(15)
        # if urls.get( current_href ) != True:
        #     status = process_page(browser, url, current_href)
        #         # we don't want to make DOS attack on SIS
        # urls[current_href] = True

finally:
    try:
        brower.close()
    except:
        pass
