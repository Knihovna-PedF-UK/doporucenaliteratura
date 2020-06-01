# Hledání doporučené literatury v knihovním fondu

Chci se pokusit najít doporučenou literaturu ze SISu v knihovním fondu. 

## Problém

V SISu jsou seznamy doporučené literatury pro jednotlivé předměty. Vkládají je
tam jednotliví vyučující. V lepším případě jsou do citace, někdy jen názvy
knih. Chceme je automaticky zpracovat a dohledat doporučovanou literaturu,
která se nachází ve fondu knihovny.

## Postup

### Vytvořit seznam literatury z Alephu

Je třeba pomocí obecného formuláře pro vyhledávání vygenerovat seznam jednotek,
co nás zajímají. Třeba podle signatury. Výsledný XML soubor zkonvertujeme 
pomocí `prirtocsv`.

Je třeba vytvořit tyto sloupce: `sysno,ck,signatura,nazev,autor,vydavatel,isbn,rok`

### Scraping literatury ze SISu

Spustíme příkazem

    make scrape

Je třeba mít nainstalované [Selenium pro Python](https://www.selenium.dev/documentation/en/) a [driver pro Firefox](https://github.com/mozilla/geckodriver/releases).

JSON soubory s bibliografickými daty vytvoříme:

    make parse
    
Je třeba mít nainstalováno GNU Parallel a [Anystyle CLI](https://anystyle.io/).

