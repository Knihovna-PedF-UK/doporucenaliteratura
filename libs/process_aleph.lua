local M = {}
local parser = require "parse_prir"
local tokenizer = require "libs.tokenize"

function M.load_data(filename)
  local f = parser.load_file(filename)
  local pos = parser.find_pos(f, {"bib-info"})
  parser.make_saves(pos)
  return parser.parse(f)
end

function M.get_titles(records)
  local titles = {}
  local used = {}
  for _, rec in ipairs(records) do
    local bibinfo = rec["bib-info"]
    local title, no = bibinfo:match("^(.-)/.+%(%#([0-9]+)")
    if not title then 
      title, no = bibinfo:match("^(.-)  .+%(%#([0-9]+)")
    end
    if not used[no] then
      local tokenized = tokenizer.tokenize(title)
      titles[#titles+1] = tokenized
      print(table.concat(tokenized, " "))
    end
    used[no] = true
  end
end


local rec = M.load_data("data/pedf_prir_2020")
tokenizer.load_unicode_data("data/UnicodeData.txt")
local titles = M.get_titles(rec)
return M
