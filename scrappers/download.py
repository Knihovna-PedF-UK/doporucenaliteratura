from selenium import webdriver
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import sys

url = sys.argv[1]
output_dir = sys.argv[2]
try:
    fireFoxOptions = webdriver.FirefoxOptions()
    fireFoxOptions.headless =  True
    brower = webdriver.Firefox(options=fireFoxOptions)
    brower.get(url)
    mainpage = brower.page_source
    maindom = BeautifulSoup(mainpage, 'html.parser')
    for link in maindom.select(".tab1 td a"):
        print(link.get('href'))

finally:
    try:
        brower.close()
    except:
        pass
