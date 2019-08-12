function getData(key, default)
    return global["data:" .. key] or default
end

function setData(key, data)
    global["data:" .. key] = data
end

function removeData(key, data)
    global["data:" .. key] = data
end

function checkAndTickInGlobal(name)
    if global[name] then
        for i, v in pairs(global[name]) do
            if v.valid then
                v:OnTick()
            else
                global[name][i] = nil
            end
        end
    end
end

function callInGlobal(gName, kName, ...)
    if global[gName] then
        for k, v in pairs(global[gName]) do
            if v[kName] then
                v[kName](v, ...)
            end
        end
    end
end

function insertInGlobal(gName, val)
    if not global[gName] then
        global[gName] = {}
    end
    table.insert(global[gName], val)
    return val
end

function removeInGlobal(gName, val)
    if global[gName] then
        for i, v in pairs(global[gName]) do
            if v == val then
                global[gName][i] = nil
                return v
            end
        end
    end
end

function setResearch(name)
    global["research:" .. name] = true
end

function isResearched(name)
    return global["research:" .. name] or false
end

function getDistance(pos1, pos2)
    return math.sqrt((pos2.x - pos1.x) ^ 2 + (pos2.y - pos1.y) ^ 2)
end

function equipmentGridHasItem(grid, itemName)
    local contents = grid.get_contents()
    return contents[itemName] and contents[itemName] > 0
end

function toDate(ticks)
    local time = ""
    local mod = 0
    ticks = ticks / 60

    local timeRange = function(time, unit)
        time = math.floor(time % unit)
        if time < 10 then
            time = "0" .. time
        end

        return time
    end

    time = timeRange(ticks, 60)
    ticks = ticks / 60
    time = timeRange(ticks, 60) .. ":" .. time
    ticks = ticks / 60
    time = math.floor(ticks) .. ":" .. time

    return time
end

function string:padRight(len, char)
    local str = self
    if not char then
        char = " "
    end

    if str:len() < len then
        str = str .. string.rep(" ", len - str:len())
    end

    return str
end

function string:contains(substr)
    return self:find(substr) ~= nil
end

function string:startsWith(prefix)
    return self:sub(1, prefix:len()) == prefix
end

function string:endWith(suffix)
    return self:sub(self:len() - (suffix:len() - 1)) == suffix
end

function string:trim()
    return self:match('^%s*(.*%S)') or ''
end

function string:ensureLeft(prefix)
    if not self:startsWith(prefix) then
        return prefix .. self
    end
    return self
end

function string:ensureRight(suffix)
    if self:sub(self:len() - (suffix:len() - 1)) ~= suffix then
        return self .. suffix
    end
    return self
end

function string:split(sSeparator, nMax, bRegexp)
    assert(sSeparator ~= '')
    assert(nMax == nil or nMax >= 1)

    local aRecord = {}
    local count = 1

    if self:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1

        local nField, nStart = 1, 1
        local nFirst, nLast = self:find(sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = self:sub(nStart, nFirst - 1)
            nField = nField + 1
            nStart = nLast + 1
            nFirst, nLast = self:find(sSeparator, nStart, bPlain)
            nMax = nMax - 1
            count = count + 1
        end
        aRecord[nField] = self:sub(nStart)
    end

    return aRecord, count
end

function searchIndexInTable(table, obj, ...)
    if table then
        for i, v in pairs(table) do
            if #{ ... } > 0 then
                for key, field in pairs({ ... }) do
                    if v then
                        v = v[field]
                    end
                end
                if v == obj then
                    return i
                end
            elseif v == obj then
                return i
            end
        end
    end
end

function searchInTable(table, obj, ...)
    if table then
        for k, v in pairs(table) do
            if #{ ... } > 0 then
                local key = v
                for i, field in pairs({ ... }) do
                    if key then
                        key = key[field]
                    end
                end
                if key == obj then
                    return v
                end
            elseif v == obj then
                return v
            end
        end
    end
end

table.search = searchInTable
table.searchIndex = searchIndexInTable

function table.len(tbl)
    local count = 0
    for k, v in pairs(tbl) do
        count = count + 1
    end
    return count
end

function table.tostring(tbl, limit)
    local tableToString
    local valToString
    local keyToString
    if not limit then
        limit = 2
    end

    valToString = function(v, circular, max)
        if "string" == type(v) then
            v = string.gsub( v, "\n", "\\n" )
            if string.match( string.gsub(v, "[^'\"]", ""), '^"+$' ) then
                return "'" .. v .. "'"
            end
            return '"' .. string.gsub(v, '"', '\\"' ) .. '"'
        else
            if max ~= 0 then
                circular = {table.unpack(circular)}
                table.insert(circular, v)
                return "table" == type(v) and tableToString(v, circular, max - 1) or tostring(v)
            end
            return "[Table]"
        end
    end
    keyToString = function(k, circular, max)
        if "string" == type(k) and string.match( k, "^[_%a][_%a%d]*$" ) then
            return k
        else
            return "[" .. valToString(k, circular, max) .. "]"
        end
    end
    tableToString = function(tbl, circular, max)
        local result, done = {}, {}

        for k, v in ipairs(tbl) do
            if type(v) == "table" then
                for index, item in ipairs(circular) do
                    if v == item then
                        table.insert(result, "[Circular]")
                        done[k] = true
                        break
                    end
                end
            end
            if not done[k] then
                done[k] = true
                if type(v) == "table" then
                    table.insert(circular, v)
                end
                table.insert(result, valToString(v, circular, max))
            end
        end
        for k, v in pairs(tbl) do
            if not done[k] then
                if type(v) == "table" then
                    for index, item in ipairs(circular) do
                        if v == item then
                            table.insert(result, keyToString(k, max) .. "=" .. "[Circular]")
                            done[k] = true
                            break
                        end
                    end
                end
                if not done[k] then
                    if type(v) == "table" then
                        table.insert(circular, v)
                    end
                    table.insert(result, keyToString(k, max) .. "=" .. valToString(v, circular, max))
                end
            end
        end
        return "{" .. table.concat(result, "," ) .. "}"
    end

    return tableToString(tbl, {}, limit)
end

function table.contains(tab, obj, field)
    for i, v in pairs(tab) do
        if field then
            if v[field] == obj then
                return true
            end
        elseif v == obj then
            return true
        end
    end
    return false
end

function table.id(obj)
    local id = tostring(obj):gsub('^%w+: ', '')
    return id
end

function Version(value)
    local function parse(str)
        local version = {}
        for i, v in pairs(str:split(".")) do
            table.insert(version, tonumber(v))
        end
        return version
    end

    local obj = {
        value = parse(value),
        isLower = function(self, version)
            if type(version) == "string" then
                version = Version(version)
            end
            for i, v in ipairs(version.value) do
                if i > #self.value then
                    return true
                elseif v > self.value[i] then
                    return true
                elseif v < self.value[i] then
                    return false
                end
            end
            return false
        end,
        isHigher = function(self, version)
            if type(version) == "string" then
                version = Version(version)
            end
            for i, v in ipairs(self.value) do
                if i > #version.value then
                    return true
                elseif v > version.value[i] then
                    return true
                elseif v < version.value[i] then
                    return false
                end
            end
            return false
        end,
        tostring = function(self)
            return table.concat(self.value, ".")
        end
    }
    return obj
end
function version_isLower(currentVersion, otherVersion)
    currentVersion = currentVersion:split(".")
    otherVersion = otherVersion.split(".")

end

function deepcopy(orig, dst)
    local copy

    if type(orig) == 'table' then
        if dst then
            copy = dst
        else
            copy = {}
        end
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function range(from, to, step)
    step = step or 1
    return function(_, lastvalue)
        local nextvalue = lastvalue + step
        if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or step == 0 then
            return nextvalue
        end
    end, nil, from - step
end

function date(time)
    year = 1970
    while time >= 31536000 do
      year = year + 1
      isLeapYear = (year%4 == 0 and year%100 ~= 0) or year%400 == 0
      if isLeapYear then
        if time < 31536000 + 86400 then
          year = year - 1
          break
        end
        time = time - 86400
      end
      time = time - 31536000
    end
    yday = 0
    for m in range(1, 12) do
      if m == 2 and isLeapYear then
          amt = 29
      elseif m == 2 then
          amt = 28
      elseif m == 4 or m == 6 or m == 9 or m == 11 then
          amt = 30
      else
          amt = 31
      end
      amts = amt * 86400
      month = m
      if time < amts then
        break
      end
      time = time - amts
      yday = yday + amt
    end
    day = math.floor(time / 86400) + 1
    yday = yday + day - 1
    time = time - (day - 1) * 86400
    hour = math.floor(time / 3600)
    time = time - hour * 3600
    minute = math.floor(time / 60)
    time = time - minute * 60
    second = time

    offset = {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334}
    afterFeb = 0
    if month < 3 then
        afterFeb = 1
    end
    aux = year - 1700 - afterFeb
    wday = 5 + ((aux + afterFeb) * 365)
    wday = wday + math.floor(aux / 4 - aux / 100 + (aux + 100) / 400)
    wday = wday + (offset[month] + (day - 1))
    wday = wday % 7
    return {
        year=year, month=month, day=day,
        hour=hour, min=minute, sec=second,
        yday=yday, wday=wday
    }
end

function weekDay(wday)
  week   = {
    'Sunday', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday',  'Friday', 'Saturday'
  }
  return week[wday + 1] or ''
end

function strtime(format, time)
    if type(time) ~= "table" then
      data = date(time)
    else
      data = time
    end
    res = ""
    while #format > 0 do
        char = string.sub(format, 1,1)
        format = string.sub(format, 2)
        if char == "%" then
            char = string.sub(format, 1,1)
            format = string.sub(format, 2)
            if char == "a" then
                dayname = weekDay(data.wday)
                res = res .. string.sub(dayname, 0, 3)
            elseif char == "A" then
                dayname = weekDay(data.wday)
                res = res .. dayname
            elseif char == "b" then
                -- TODO: short month name
            elseif char == "B" then
                -- TODO: Full month name
            elseif char == "c" then
                res = strtime("%x T %X", data)
            elseif char == "d" then
                res = res .. string.format("%02d", data.day)
            elseif char == "H" then
                res = res .. string.format("%02d", data.hour)
            elseif char == "I" then
                hour = data.hour
                if hour > 12 then
                    hour = hour - 12
                end
                if hour == 0 then
                    hour = 12
                end
                res = res .. string.format("%02d", hour)
            elseif char == "j" then
                res = res .. string.format("%03d", data.yday)
            elseif char == "m" then
                res = res .. string.format("%02d", data.month)
            elseif char == "M" then
                res = res .. string.format("%02d", data.min)
            elseif char == "p" then
                if data.hour < 12 then
                    res = res .. "a.m."
                else
                    res = res .. "p.m."
                end
            elseif char == "S" then
                res = res .. string.format("%02d", data.sec)
            elseif char == "U" then
                -- TODO: add week number of the year (Sun first day)
            elseif char == "w" then
                res = res .. data.wday
            elseif char == "W" then
                -- TODO: add week number of the year (monday first day)
            elseif char == "x" then
                res = res .. strtime("%Y-%m-%d", data)
            elseif char == "X" then
                res = res .. strtime("%H:%M:%S", data)
            elseif char == "y" then
                res = res .. string.sub(data.year, 2)
            elseif char == "Y" then
                res = res .. data.year
            elseif char == "Z" then
                -- Do nothing as we are pretending no timezone
            else
                res = res .. "%" .. char
            end
        else
            res = res .. char
        end
    end
    return res
end
