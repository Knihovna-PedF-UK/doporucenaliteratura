.PHONY: scrape
pedf_url = "https://is.cuni.cz/studium/predmety/index.php?do=ustav&fak=11410&kod=" 
katedry_dir = data/katedry
predmety_dir = data/predmety

data/UnicodeData.txt:
	mkdir -p data
	mkdir -p $(katedry_dir)
	mkdir -p $(predmety_dir)
	cp `kpsewhich UnicodeData.txt` data/


scrape: katedry predmety

katedry: 
	python scrappers/download.py $(pedf_url) data/katedry

predmety: data/katedry/*
	@for f in $^; do python scrappers/katedry.py $${f} $(pedf_url) $(predmety_dir); done



