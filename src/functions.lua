-- Write to console if debug=true
function QuickApp:d(msg)
    if self.debugOn then self:debug(msg) end
end

function QuickApp:getRateDate(dateString, format, addHour, timezoneOffset)
    if format == nil then format = "%Y-%m-%d %H:%M" end
    if addHour == nil then addHour = 0 end
    if timezoneOffset == nil then timezoneOffset = 0 end

    -- Convert input dateString = "2022-12-25 23:00" to Lua date
    local iyear, imonth, iday, ihour, iminute = dateString:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    local timestamp = os.time({year = iyear, month = imonth, day = iday, hour = ihour, min = iminute}) + timezoneOffset
    return os.date(format, timestamp + (addHour * 60 * 60))
end

-- Get ENTSO-e next day price release date in local time
function QuickApp:getRateReleaseTime(timezoneOffset)
    if timezoneOffset == nil then timezoneOffset = 0 end
    return os.date("!%H", os.time({year=2000, month=1, day=1, hour=self.nextday_releaseTime, min=0}) + timezoneOffset)
end

-- Count items in a Lua table
function QuickApp:tableCount(T)
    if T == nil then return 0 end
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Convert xml input dateString = "2022-12-25T23:00Z" to Lua date
function QuickApp:getXmlDate(xmlString, name, format)
    local dateString = self:getXmlElement(xmlString, name)
    local iyear, imonth, iday, ihour, iminute = dateString:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+)Z")
    local timestamp = os.time({year = iyear, month = imonth, day = iday, hour = ihour, min = iminute})
    return os.date(format, timestamp)
end

-- Get xml element value
function QuickApp:getXmlElement(data, name)
    return data:match("<"..name..">(.-)</"..name..">")
end

-- Extract ENTSO-e prices from response xml into Lua table
function QuickApp:xml2PriceTable(xml)
    local priceTable = {}
    local ni, c, label, xarg, empty
    local i, j = 1, 1

    while true do
        ni, j, c, label, xarg, empty = string.find(xml, "<(%/?)([%w:_]+)(.-)(%/?)>", i)
        if not ni then break end
        local text = string.sub(xml, i, ni-1)
   
        if not string.find(text, "^%s*$") and label == "price" then
            table.insert(priceTable, text)
        end

        i = j+1
    end

    return priceTable
end

function QuickApp:getLocalTariffRate(mainRate, exchangeRate, tax)
    if (exchangeRate == nil) then exchangeRate = 1 end
    if (tax == nil or tax == 0) then tax = 1 end
    if (tax > 1) then tax = (tax / 100) + 1 end -- Convert input tax in % to decimal if > 1
    
    -- Recalculate main rate from EUR/mWh to {local currency}/kWh * tax
    local rate = tonumber(string.format("%.2f",((tonumber(mainRate)*tonumber(exchangeRate)/1000)*tax)))
    if rate <= 0 then rate = 0.00001 end -- FIBARO can't accept 0 or negative tariff rate price :(
    return rate
end

function QuickApp:getRank(value)
    -- Set defaults if not valid input value
    if (value == nil) then return "" end
    if (value == "nan") then return "" end
    if (value == "--") then return "" end
    if (value == 0) then return "" end
    
    local medValue = tonumber(self.mediumPrice)
    if (medValue == nil) then medValue = self:getDefaultMediumPrice() end
    
    -- Calculate percent from medium energy rate 
    local percent = (value / medValue) * 100

    -- Return price rank from calculated percent based on medium price and variable rank value
    local rank = "VeryLOW"
    if (percent >= self.low_rank) then rank = "LOW" end
    if (percent >= self.medium_rank) then rank = "MEDIUM" end
    if (percent >= self.high_rank) then rank = "HIGH" end
    if (percent >= self.veryhigh_rank) then rank = "VeryHIGH" end

    self:d("Set the rank level between percentage of " .. value .. " and " .. medValue .. " = " .. rank .. " (" .. percent .. "%)")

    return rank
end

function QuickApp:getRankIcon(value)
    if (value == "VeryHIGH") then return "🔴" end
    if (value == "HIGH") then return "🟠" end
    if (value == "MEDIUM") then return "🟡" end
    if (value == "LOW") then return "🔵" end
    if (value == "VeryLOW") then return "🟢" end
    return "⛔"
end

function QuickApp:getNextDirection(currentValue, nextValue)
    if (currentValue == nil) then currentValue = 0 end
    if (nextValue == nil) then nextValue = 0 end
    if (currentValue > nextValue) then return "⇩" end
    if (currentValue < nextValue) then return "⇧" end
    return "⇨"
end
