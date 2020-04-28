from selenium import webdriver

try:
    fireFoxOptions = webdriver.FirefoxOptions()
    fireFoxOptions.headless =  True
    brower = webdriver.Firefox(options=fireFoxOptions)

    brower.get('https://pythonbasics.org')
    print(brower.page_source)
finally:
    try:
        brower.close()
    except:
        pass
