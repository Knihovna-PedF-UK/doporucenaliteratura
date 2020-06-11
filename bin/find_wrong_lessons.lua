-- find lessons where multiple citations are on one line
--

for _, filename in ipairs(arg) do
  local wrong = false
  for line in io.lines(filename) do
    if line:match("isbn.*isbn") then
      wrong = true
    elseif line:match("ISBN.*ISBN") then
      wrong = true
    end
  end
  if wrong == true then print(filename) end
end
