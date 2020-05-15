local M = {}
local tokenizer = require "libs.tokenize"

function M.load_data(filename)
  local function read_tsv(line)
    local r = {}
    for x in line:gmatch("([^\t]*)") do r[#r+1] = x end
    return r
  end
  local function read_headers(line)
    return read_tsv(line)
  end
  local function read_line(line, headers)
    local r = read_tsv(line)
    local rec = {}
    -- save data under headers, not column number
    for i, data in ipairs(r) do rec[headers[i]] = data end
    return rec
  end

  local records = {}
  local headers
  for line in io.lines(filename) do
    if not headers then
      headers = read_headers(line)
    else
      records[#records+1] = read_line(line, headers)
    end
  end
  return records
end

local function tokenize(title)
  return tokenizer.tokenize(title,{"Lu", "Ll", "Lt","Nd" } )
end

local function update_index(index, rec, field )
  local value = rec[field]
  local sysno = rec["sysno"]
  local subtable = index[field] or {}
  local values = subtable[value] or {}
  values[#values + 1] = sysno
  subtable[value] = values
  index[field] = subtable
  return index
end

local function make_tokenized_index(index, rec, field)
  if not rec[field] then return index end
  local subtable = index["tokenized_" .. field] or {}
  local sysno = rec["sysno"]
  for _, v in ipairs(rec[field]) do
    local values = subtable[v] or {}
    values[#values + 1] = sysno
    subtable[v] = values
  end
  index["tokenized_" .. field] = subtable
end

local ngram_len = 4
local function make_ngrams(text)
  local len = string.len(text)
  if len <= ngram_len then
    return {text}
  end
  local ngrams = {}
  for i = 1, len - ngram_len do
    local word = string.sub(text, i, i + ngram_len - 1)
    ngrams[#ngrams+1] = word
  end
  return ngrams
end

local function make_ngram_index(index, rec, field)
  local ngrams = make_ngrams(rec[field])
  local subtable = index["ngrams_" .. field] or {}
  local sysno = rec["sysno"]
  for _,ngram in ipairs(ngrams) do
    local values = subtable[ngram] or {}
    -- save sysno only once for each text
    values[sysno] = true
    subtable[ngram]= values
  end
 index["ngrams_" .. field] = subtable
end
function M.make_index(records)
  local newrecords = {}
  local index = {}
  for _, rec in ipairs(records) do
    local title = rec["nazev"]
    local no = rec["sysno"]
    if title and not newrecords[no] then
      local newrec = {}
      -- copy old record
      for k, v in pairs(rec) do newrec[k] = v end
      -- tokenize some fields
      for _, t in ipairs{ "nazev", "autor", "vydavatel", "isbn" } do
        local tokenized = tokenize(rec[t])
        newrec["tokenized_" .. t ] = tokenized
        newrec["joined_" .. t] = table.concat(tokenized) -- save table and joined 
      end
      update_index(index, newrec, "nazev")
      update_index(index, newrec, "joined_nazev")
      update_index(index, newrec, "autor")
      update_index(index, newrec, "vydavatel")
      update_index(index, newrec, "joined_isbn") -- search for isbn without dashes
      make_tokenized_index(index, newrec, "tokenized_author")
      make_ngram_index(index, newrec, "joined_nazev")
      newrecords[no] = newrec
    end
  end
  return newrecords, index
end


local function search_ngrams(ngram_index, text)
  local ngrams = make_ngrams(text)
  local points = 1 / #ngrams
  local found_ids = {}
  for _, w in ipairs(ngrams) do
    local current_docs = ngram_index[w] or {}
    for id, _ in pairs(current_docs) do -- sysnos are table keys
      local sum = found_ids[id] or 0
      sum = sum + points
      found_ids[id] = sum
    end
  end
  return found_ids
end

local rec = M.load_data("data/pedf_f_small.tsv")
tokenizer.load_unicode_data("data/UnicodeData.txt")

local records, index = M.make_index(rec)
print "index build"
local ngram_index = index["ngrams_joined_nazev"]
local titles = {}
for _, rec in pairs(records) do titles[#titles+1] = rec["nazev"] end
for i = 1, 1 do
  local num = math.random(1, #titles) 
  local title = titles[num]
  local ids = search_ngrams(ngram_index, title)
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


return M
