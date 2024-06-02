local lume = require'lume'

local prim = true

for i = 1, 20 do io.write(i % 10) end
print()

for i = 0, 21 do
  local current, last = i, 5
  local min, max = 0, 20

  local bar = string.rep(prim and '-' or '—', 20)
  -- local lastPos = lume.clamp(math.floor(lume.mapvalue(last, min, max, 1, 20)), 1, 20)
  local barPos = lume.clamp(math.floor(lume.mapvalue(current, min, max, 1, 20)),
                            1, 20)
  -- local barStr = string.sub(bar, 1, lastPos-1)..'+'..string.sub(bar, lastPos+1)
  barStr = bar:sub(1, barPos - 1) .. '#' .. bar:sub(barPos + 1)

  print(barStr, barPos, i)
end
for i = 1, 20 do io.write(i % 10) end
