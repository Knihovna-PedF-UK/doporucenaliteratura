-- Hledat záznamy z json souborů v databázi alephu
local json = require "json"
local process_aleph = require "libs.process_aleph"


local rec = process_aleph.load_data(arg[1])
process_aleph.load_tokenizer_data("data/UnicodeData.txt")
local records, index = process_aleph.make_index(rec)

local ngram_nazev = index["ngrams_joined_nazev"]
local ngram_author = index["ngrams_joined_autor"]

local isbn_data =  {}
local records_isbn = {}
local unprocessed_isbn = {}
local isbn_citations = {} -- citation data for isbn
local sysno_cache = {} -- mapping between sysnos and record ids

local function flatten_table(v)
  if type(v) == "string" then 
    return v
  elseif type(v) == "table" then
    local buff = {}
    for _, x in ipairs(v) do
      buff[#buff+1]  = flatten_table(x)
    end
    return table.concat(buff)
  end
  return v
end

local function clean_isbn(isbn)
  return isbn:gsub("[%-– ]", "")
end

local function match_isbn(x)
  local isbn = x:match("([0-9xX%-–]+)")
  if isbn then
    -- save the matched isbn
    local matched_isbn = isbn
    -- clean isbn
    -- test if the length is correct
    local len = string.len(clean_isbn(isbn))
    if len == 10 or len == 13 then
      return matched_isbn
    end
  end
  return false
end

local function find_isbn(rec) 
  -- process all fields in record and try to find isbn
  local rec = rec or {}
  for _, v in pairs(rec) do
    local x = match_isbn(tostring(flatten_table(v)))
    if x then return x end
  end
  return nil
end


local function update_isbn(isbn, rec) 
  local nisbn = clean_isbn(isbn)
  -- save original isbn
  unprocessed_isbn[nisbn] = isbn
  local count = isbn_data[nisbn] or 0
  isbn_data[nisbn] = count + 1
  -- save citation data
  isbn_citations[isbn] = rec
  
end

local function update_rec_isbn(isbn,rec) 
  local isbn = clean_isbn(isbn)
  records_isbn[isbn] = rec
end

-- we will create fake isbn for records without real isbn 
local fake_isbn_count = 0
-- try to find isbn in records parsed by anystyle
local function process(filename, data)
  local f = io.open(filename, "r") 
  local content = f:read("*all")
  f:close()
  local data = json.decode(content)
  local isbns = data.isbn or {}
  for k,v in ipairs(data) do
    -- isbn was detected by anystyle
    local found_isbn = false
    if v.isbn then
      for _, x in ipairs(v.isbn) do
        -- update only valid isbns
        if match_isbn(x) then
          update_isbn(x,v)
          found_isbn = true
        end
      end
    else
      -- try to find isbn in text
      local isbn =  find_isbn(v)
      if isbn then
        update_isbn(isbn,v)
        found_isbn = true
      end
    end
    if found_isbn == false then
      -- make fake isbn, in order to keep all records
      fake_isbn_count = fake_isbn_count + 1
      local fake_isbn = "no_isbn_" .. fake_isbn_count
      update_isbn(fake_isbn, v)
    end
  end
  return data
end

local function get_authors(rec)
  local rec = rec or {}
  local t = {}
  local authors = rec.author or {}
  for _, x in ipairs(authors) do t[#t+1] = (x.family or "") .. ", " .. (x.given or "") end
  return table.concat(t, "; ")
end

local function find_in_ngrams(index, what)
  local ids = process_aleph.search_ngrams(index, what)
  local xxx = {}
  for id, sum in pairs(ids) do xxx[#xxx+1]= {id = id, sum= sum} end
  table.sort(xxx, function(a,b) return a.sum > b.sum end)
  return xxx
end

local function wrong_record(nazev, autor)
  if nazev == "" or autor == "," or autor == ", Literatura" then 
    return true 
  end
end

local find_names_cache = {}
local function is_cached(nazev,autor)
  -- don't lookup multiple times for the identical publication
  local lookup_name = nazev .. autor
  -- cleanup a bit
  lookup_name = lookup_name:gsub("%s*", "")
  if find_names_cache[lookup_name] then
    return true
  end
  find_names_cache[lookup_name] = true
  return false
end

-- find records by name and author
local function find_names(orig_isbn)
  local rec = isbn_citations[orig_isbn] 
  local nazev = flatten_table(rec.title or {}) or ""
  local autor = get_authors(rec) or ""
  -- don't lookup records without authors and title
  -- they are mostly badly recognized records anyway
  if wrong_record(nazev, autor) then
    return nil 
  end
  if is_cached(nazev, autor) then return nil end
  local nazev_ids = find_in_ngrams(ngram_nazev, nazev)
  local autor_ids = find_in_ngrams(ngram_author, autor)
  -- return sysno that is contained in first five names and also in authors
  local first_names = {}
  for i = 1, 5 do
    -- find first 5 records
    local x = nazev_ids[i]
    if x then -- there can be less than five matches, so handle that
      local sysno = x.id  
      first_names[sysno] = x.sum
    end
  end
  for _, aut in ipairs(autor_ids) do 
    local sysno = aut.id
    local sum = first_names[sysno]
    if sum then 
      local rec = isbn_citations[orig_isbn]
      local nazev = flatten_table(rec.title or {}) or ""
      local autor = get_authors(rec) or ""
      if sum > 0.5 then
        -- return just records above certain threshold
        -- false positives may happen anyway
        return sysno_cache[sysno]
      end
    end
  end
  -- return nil by default
end
 

for i = 2, #arg do
  local filename = arg[i]
  -- print(i,filename)
  data = process(filename, data)
end

for i, x in ipairs(rec) do
  local isbn = match_isbn(x.isbn)
  if isbn then
    update_rec_isbn(isbn, x)
  end
  -- add link between sysno and record number
  -- multiple records may have the same sysno, but it doesn't matter, we just need it for bib info and call no
  local sysno = x.sysno
  if sysno then 
    sysno_cache[sysno] = x 
  end
end

-- cache names and authors from sis, in order to prevent multiple lookups for the same record
local sis_used = {}
-- print found results
local i = 0
print("poradi", "isbn", "isbn aleph", "predmetu", "sysno", "signatura", "nazev", "nazev v citaci", "autor")
for isbn, count in pairs(isbn_data) do
  local orig_isbn= unprocessed_isbn[isbn]
  local rec = records_isbn[isbn] or find_names(orig_isbn)
  if rec then
    -- records found in aleph
    i = i + 1
    local curr_isbn = rec.isbn
    if not curr_isbn or curr_isbn == "" then curr_isbn = orig_isbn end
    local cit_rec = isbn_citations[orig_isbn] 
    local nazev_cit = flatten_table(cit_rec.title or {}) or ""
    print(i, curr_isbn, rec.isbn , count, rec.sysno, rec.signatura,  rec.nazev, nazev_cit, rec.autor )
  else
    -- records that haven't been found in aleph
    -- get the SIS record
    local rec = isbn_citations[orig_isbn] 
    local nazev = flatten_table(rec.title or {}) or ""
    local autor = get_authors(rec) or ""
    -- don't lookup for the same publication multiple times
    local lookup_name = nazev .. autor
    lookup_name = lookup_name:gsub("%s", "")
    if not sis_used[lookup_name] then
      local sysno = rec.sysno or ""
      if orig_isbn:match("no_isbn") and wrong_record(nazev, autor)  then
        -- don't print empty records
      else
        print(i, orig_isbn, "",  count, "", sysno,"",  nazev, autor)
      end
    end
    sis_used[lookup_name] = true
  end
end




