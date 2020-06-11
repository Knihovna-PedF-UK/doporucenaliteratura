-- jen chci vyzkoušet, jestli funguje hledání názvů
local process_aleph = require "libs.process_aleph"


local rec = process_aleph.load_data("data/pedf_f_small.tsv")
process_aleph.load_tokenizer_data("data/UnicodeData.txt")
local tokenize = process_aleph.tokenize

local records, index = process_aleph.make_index(rec)
print "index build"
local ngram_index = index["ngrams_joined_nazev"]
local titles = {}
for _, rec in pairs(records) do titles[#titles+1] = rec["nazev"] end
for i = 1, 1 do
  local num = math.random(1, #titles) 
  local title = titles[num]
  local ids = process_aleph.search_ngrams(ngram_index, title)
  local xxx = {}
  for id, sum in pairs(ids) do xxx[#xxx+1]= {id = id, sum= sum} end
  table.sort(xxx, function(a,b) return a.sum > b.sum end)
  local first = xxx[1] 
  if first then
    local first_title = records[first.id]["nazev"]
    -- if first_title ~= title then
      print ("------------------" .. i)
      print(title, table.concat(tokenize(title)))
      print "=================="
      for i = 1, 10 do
        local x = xxx[i]
        if x then 
          local nazev = records[x.id]["nazev"]
          print(x.sum, nazev, table.concat(tokenize(nazev)))
        end
      end
    -- end
  end
end

