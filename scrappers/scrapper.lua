-- I've found that we need JS support to download files from SIS. that is really stupid.
-- I will use Python and Selenium instead, as it can use headless Firefox
local function scrape(url)
  local f = io.popen("python scrappers/download.py ".. url,"r")
  local result = f:read("*all")
  f:close()
  return result
end

local function get_base_url(url)
  -- remove php file and params from url
  return url:gsub("[^%/]+$", "")
end

local function url_dirs(params)
  local t = {}
  for x in params:gmatch("([^%/]+)") do t[#t+1] = x end
  return t
end

local function url_decode(url)
  -- just replace &amp;
  return url:gsub("%&amp;", "&")
end


local function urljoin(base, sub)
  -- this is just naive attempt, but it is enough for our purpose
  local host, params = base:match("(.+://[^%/]+)(.+)")
  -- join params from base and sub url
  local base_dirs = url_dirs(params)
  local sub_dirs = url_dirs(sub)
  for _, x in ipairs(sub_dirs) do
    -- remove last element from the base_dirs to get the parent dir
    if x == ".." then 
      table.remove(base_dirs) 
    else
      base_dirs[#base_dirs + 1] = x
    end
  end
  return host .. "/" .. table.concat(base_dirs, "/")
end


return {
  scrape = scrape,
  urljoin = urljoin,
  get_base_url = get_base_url,
  url_decode = url_decode

}
