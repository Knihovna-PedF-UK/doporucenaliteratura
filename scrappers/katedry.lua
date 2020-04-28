local scrapper = require "scrappers.scrapper"
local webpage = arg[1]
local base_url = scrapper.get_base_url(webpage)
local new_url = scrapper.url_decode(scrapper.urljoin(base_url,"../predmety/index.php?do=ustav&amp;fak=11410&amp;kod=41-UVRV"))
local page = scrapper.scrape(new_url)
print(new_url)
print(page)


