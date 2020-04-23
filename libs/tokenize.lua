-- Tokenize Unicode strings
-- features: remove accents, convert to lower case, ignore non-letters
--
-- load unicode data
local M = {}
local raw_unicodes = {}
function M.load_unicode_data(filename)
  local i = 0
  for line in io.lines(filename) do
    -- each line is one character
    -- we don't parse all characters, as most of them are not necessary in general
    raw_unicodes[i] = line
    i = i + 1
  end
end

M.
local s = "příliš žluťoučký"
for 

return M
