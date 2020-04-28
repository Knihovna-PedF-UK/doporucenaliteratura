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
    if not title then print(bibinfo) end
    if title and not used[no] then
      local tokenized = tokenizer.tokenize(title,{"Lu", "Ll", "Lt","Nd" } )
      titles[#titles+1] = {tokenized = tokenized, title = title}
      -- print(table.concat(tokenized, " "))
      used[no] = true
    end
  end
end


local rec = M.load_data("data/pedf_prir_2020")
tokenizer.load_unicode_data("data/UnicodeData.txt")
local titles = M.get_titles(rec)
return M
