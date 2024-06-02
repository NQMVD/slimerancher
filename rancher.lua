local lume = require'lib.lume'
local serpent = require'lib.serpent'
local log = require'lib.log'
local args = {...}

local colors = {}
colors.green = function(s) return '\27[32m' .. s .. '\27[0m' end
colors.yellow = function(s) return '\27[33m' .. s .. '\27[0m' end
colors.red = function(s) return '\27[31m' .. s .. '\27[0m' end
colors.grey = function(s) return '\27[31m' .. s .. '\27[0m' end

local plortList = {
  'Pink', 'Cotton', 'Phosphor', 'Tabby', 'Angler', 'Rock', 'Honey', 'Boom',
  'Puddle', 'Fire', 'Batty', 'Crystal', 'Hunter', 'Flutter', 'Ringtail',
  'UNKNOWN', 'Yolk', 'Gold'
}
local unlocked, prices = {}, {}

local function addPrice(plort, price)
  if not prices[plort] then prices[plort] = {} end
  lume.push(prices[plort], price)
end

local function saveData()
  local f = assert(io.open('data.lua', 'w'))
  f:write(serpent.dump({unlocked = unlocked, prices = prices}))
  f:close()
end

local function loadData()
  local data = {}
  local f = io.open('data.lua', 'r')
  if f then
    local content = f:read '*all'
    f:close()
    local chunk, err = load(content)
    log.debug(chunk)
    if chunk then
      data = chunk()
      if data == nil then
        log.warn('Error loading data:', err)
        log.info'Creating new data'
        unlocked, prices = {}, {}
        saveData()
        return
      end
      log.debug(data)
      unlocked = data.unlocked or {}
      prices = data.prices or {}
    else
      log.warn('Error loading data:', err)
      log.info'Creating new data'
      unlocked, prices = {}, {}
      saveData()
      return
    end
  end
end

local function getTrend(list)
  local size = lume.count(list)
  if size < 2 then return 0 end
  local last = list[size]
  local secondlast = list[size - 1]
  return last - secondlast
end

local function getStat(plort)
  local pricelist = prices[plort]
  if not pricelist then return 'NONE' end
  local max = lume.max(pricelist)
  local min = lume.min(pricelist)
  local trend = getTrend(pricelist)
  local current = lume.last(pricelist)
  local last = pricelist[lume.count(pricelist) - 1]
  local rec = '[KEEP]'
  if trend > max * 0.1 and current > max / 4 then
    rec = colors.green'[SELL]'
  elseif trend > 0 then
    rec = colors.yellow'[WAIT]'
  elseif trend <= 0 then
    rec = colors.red'[KEEP]'
  end
  local bar = string.rep('-', 20)
  local lastPos = lume.clamp(math.floor((last - min) / (max - min) * 20), 1, 20)
  local barPos = lume.clamp(math.floor((current - min) / (max - min) * 20), 1, 20)
  local barStr = string.sub(bar, 1, lastPos - 1) .. '+' .. string.sub(bar, lastPos + 1)
  barStr = string.sub(barStr, 1, barPos - 1) .. '#' .. string.sub(barStr, barPos + 1)
  return string.format(' %s:%s %s | %d => %3d => %d | %d [%s] %d',
                       plort, string.rep(' ', 8 - #plort), rec,
                       last, trend, current, min, barStr, max)
end

local function printPrices()
  local result = {}
  print' Prices: '
  for plort in pairs(prices) do lume.push(result, getStat(plort)) end
  local _, numPos = string.find(getStat'Pink', ' => ')
  local function sortFunc(a, b)
    local trend1 = a:sub(numPos, numPos + 3)
    local trend2 = b:sub(numPos, numPos + 3)
    local trend1num = tonumber(trend1) or -math.huge
    local trend2num = tonumber(trend2) or -math.huge
    return trend1num > trend2num
  end
  table.sort(result, sortFunc)
  print' Name      Sugges | Last Trend Curr | Min        Range         Max'
  print' -----------------+-----------------+-------------------------------'
  for _, line in ipairs(result) do print(line) end
end

-----------------------------------------------------------------------------------------------

log.level = 'error'
loadData()

if #args == 0 then
  print('Unlocked plorts: ', lume.count(unlocked))
  for _, plort in ipairs(plortList) do
    if unlocked[plort] then
      io.write(string.format('Enter Price for [%s]: ', plort))
      local input = io.read()
      if input == '' then
        print'No price entered, skipping...'
      elseif input == 'q' then
        print'quiting'
        os.exit(0)
      else
        local price = tonumber(input)
        while tonumber(price) == nil do
          io.write(string.format('Enter Price for [%s]: ', plort))
          price = tonumber(io.read())
        end
        addPrice(plort, price)
      end
    end
  end
  saveData()
  print'--------------------------------'

  printPrices()

elseif args[1] == 'prices' then
  printPrices()

elseif args[1] == 'undo' then
  print'Removing the last entry of all Pricelists'
  log.debug(serpent.block(prices))
  for _, pricelist in pairs(prices) do lume.pop(pricelist) end
  log.debug(serpent.line(prices))
  saveData()

elseif args[1] == 'backup' then
  print'Backing up'
  local f = assert(io.open('backup.lua', 'w'))
  f:write(serpent.dump({unlocked = unlocked, prices = prices}))
  f:close()

elseif args[1] == 'unlock' then
  local plort = args[2]
  if not plort then
    print('Usage: rancher unlock <plort>')
    return
  end
  if not lume.find(plortList, plort) then
    print('Invalid plort')
    return
  end
  if unlocked[plort] then
    print('Plort already unlocked')
    return
  end
  unlocked[plort] = true
  saveData()
  print('Plort unlocked')
  return

elseif args[1] == 'unlocked' then
  print('Unlocked plorts: ', lume.count(unlocked))
  for plort, _ in pairs(unlocked) do print(plort) end

else
  print('Usage: rancher [prices|unlock...|unlocked|undo|backup]')
end

