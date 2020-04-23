-- Tokenize Unicode strings
-- features: remove accents, convert to lower case, ignore non-letters
--
-- load unicode data
local M = {}
local raw_unicodes = {}
local parsed_unicodes = {}
function M.load_unicode_data(filename)
  local i = 0
  for line in io.lines(filename) do
    -- each line is one character
    -- we don't parse all characters, as most of them are not necessary in general
    raw_unicodes[i] = line
    i = i + 1
  end
end

-- convert hex codepoint string to number
local function codehextonum(char)
  return tonumber(char, 16)
end

function M.char_info(codepoint)
  local info = parsed_unicodes[codepoint]
  if info then return info end
  info = {}
  for part in raw_unicodes[codepoint]:gmatch("([^;]*)") do
    info[#info+1] = part
  end
  parsed_unicodes[codepoint] = info
  return info
end

local base_chars = {}
-- get base character for accented letters
function M.get_base_char(codepoint)
  local base = base_chars[codepoint]
  if base then return base end
  local info  = M.char_info(codepoint)
  local compounds = info[6] -- here is info about compound characters
  if compounds == "" then -- just return the original codepoint if it is not compound
    base_chars[codepoint] = codepoint
    return codepoint
  end
  base = codehextonum(compounds:match("^([0-9A-F]+)"))
  base_chars[codepoint] = base
  return base
end

local lower_cases = {}
-- convert codepoint to lower case
function M.lower_case(codepoint)
  local lower = lower_cases[codepoint]
  if lower then return lower end
  local info = M.char_info(codepoint)
  lower = codehextonum(info[14]) or codepoint
  lower_cases[codepoint] = lower
  return lower
end

local codepoint_categories = {}
function M.get_category(codepoint) 
  local category = codepoint_categories[codepoint]
  if category then return category end
  local info = M.char_info(codepoint)
  category = info[3]
  codepoint_categories[codepoint] = category
  return category
end

function M.tokenize(str, allowed_types)
  local words = {}
  local update_words = function(current_word)
    if current_word~="" then
      words[#words+1] = current_word
    end
    return ""
  end
  local allowed_types = allowed_types or {"Lu", "Ll", "Lt"}
  local reversed_allowed = {}
  for _, x in ipairs(allowed_types) do reversed_allowed[x] = true end
  local current_word = ""
  for pos, codepoint in utf8.codes(str) do
    local typ = M.get_category(codepoint)
    if reversed_allowed[typ] then
      local char = utf8.char(M.lower_case(M.get_base_char(codepoint)))
      current_word = current_word .. char
    else
      current_word = update_words(current_word)
    end
  end
  update_words(current_word)
  return words
end



M.load_unicode_data("data/UnicodeData.txt")
local s =[[
    Lidé mohou být nově na veřejnosti až v desetičlenné skupině, od pondělí se otevřou vysoké školy, nové pacienty také mohou začít přijímat lázně. Ministr zdravotnictví Adam Vojtěch ve čtvrtek večer po jednání vlády představil, jaká opatření, které byly přijaty kvůli šíření koronaviru, nově uvolní.
    ilustrační snímek

    ilustrační snímek | foto:  Michal Růžička, MAFRA
    1Volný pohyb

    Vláda od pátku ruší zákaz volného pohybu osob. Epidemiologická situace v Česku podle ministra Vojtěcha umožňuje, aby došlo k uvolnění restrikcí.
    2Vysoké školy

    Od pondělí se otevřou vysoké školy pro všechny studenty. „V krizovém opatření se od 27. dubna umožňuje účast ve všech ročnících vysokých škol, už to není pouze ten poslední, jak to bylo definováno původně,“ řekl ministr.
    3Cestování do zahraničí

    Po uvolnění zákazu volného pohybu osob bude opět možné cestovat do zahraničí. Při návratu bude dál nutný negativní test nebo karanténa.
    4Lázně

    Lázně mohou začít za určitých podmínek přijímat pacienty do léčebně-rehabilitační péče. Ministerstvo zdravotnictví to povolilo mimořádným opatřením.
    5Zdravotnictví

    Kraje budou muset nově zajistit pro seniory s nemocí covid-19 pouze deset volných lůžek na 100 000 obyvatel. Dosud to bylo 60 lůžek. Hejtmanům vadilo to, že opatření je plošné a nerespektuje podle nich reálné potřeby jednotlivých krajů.

    Zdroj: https://www.idnes.cz/zpravy/domaci/koronavirus-opatreni-uvolnovani-prehledne-vysoke-skoly-cestovani-volny-pohyb.A200423_222347_domaci_aug
]]

local words = M.tokenize(s)
print(table.concat(words, " "))
-- for _, code in utf8.codes(s) do
--   local info = M.char_info(code)
--   print(info[2], info[6], utf8.char(M.lower_case(M.get_base_char(code))), utf8.char(code))
-- end

return M
