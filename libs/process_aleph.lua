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


function M.search_ngrams(ngram_index, text )
  local tokenized = table.concat(tokenize(text))
  local ngrams = make_ngrams(tokenized)
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

-- load Unicode data for tokenizer
function M.load_tokenizer_data(filename)
  tokenizer.load_unicode_data(filename)
end

M.tokenize = tokenize

return M
