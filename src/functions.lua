-- Write to console if debug=true
function QuickApp:d(msg)
    if self.debugOn then self:debug(msg) end
end

-- Get currency symbol
function QuickApp:getCurrencySymbol()
    local currency = self.currency
    if (self.currency == nil) then currency = "EUR" end
    if (currency == "EUR") then return "€" end
    if (currency == "USD") then return "$" end
    if (currency == "GBP") then return "£" end
    if (currency == "YEN") then return "¥" end
    if (currency == "SEK") then return "Kr" end
    if (currency == "NOK") then return "Kr" end
    if (currency == "DKK") then return "Kr" end
    return currency
end

-- Get Lua date format from FIBARO date format
function QuickApp:getDateFormat()
    if self.dateFormat == "YY-MM-DD" then return "%Y-%m-%d" end
    if self.dateFormat == "DD.MM.YY" then return "%d.%m.%Y" end
    if self.dateFormat == "MM/DD/YY" then return "%m/%d/%Y" end
    return "%Y-%m-%d"
end

-- Get value format
function QuickApp:getValueFormat()
    if (self.decimals == nil) then self.decimals = self:getDefaultPriceDecimals() end
    return "%." ..tostring(self.decimals) .."f"
end

function QuickApp:toLocalDate(dateString, timezoneOffset, format)
    if dateString == "" then return "" end
    if timezoneOffset == nil then timezoneOffset = 0 end
    if format == nil then format = "%Y%m%d" end

    -- Convert input dateString = "2022-12-25 23:00" to table Id date "20221225"
    local iyear, imonth, iday, ihour, iminute = dateString:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    local timestamp = os.time({year = iyear, month = imonth, day = iday, hour = ihour, min = iminute}) + timezoneOffset
    return os.date(format, timestamp)
end

function QuickApp:toDate(dateId, hour, format, addHour)
    if dateId == nil or dateId == "" then return "" end
    if hour == nil or hour == "" then hour = 0 end
    if format == nil then format = "%Y-%m-%d" end
    if addHour == nil then addHour = 0 end

    -- Convert input dateId = "20221225" to Lua date format
    local iyear, imonth, iday = dateId:match("^(%d%d%d%d)(%d%d)(%d%d)$")
    local timestamp = os.time({year = iyear, month = imonth, day = iday, hour = hour})
    return os.date(format, timestamp + (addHour * 60 * 60))
end

function QuickApp:isDisplayPanelUpToDate()
    --self:debug("Is Display Panel Up To Date: " ..tostring(self.exchangeRate) .." " ..tostring(self.lastExchange) .." " ..tostring(self.dataChanged))
    
    if self.dataChanged then return false end
    --if self.lastExchange ~= self.exchangeRate then 
    --    self.lastExchange = self.exchangeRate
    --    return false
    --end
    
    if self.lastVariableUpdate == nil or self.lastVariableUpdate == "" then return false end   

    -- Convert input self.lastVariableUpdate = "2022-12-25 23:00" to hour
    local iyear, imonth, iday, ihour, iminute = self.lastVariableUpdate:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    local timestamp = os.time({year = iyear, month = imonth, day = iday, hour = ihour, min = iminute, sec = 0})
    local lastHourUpdate = tonumber(os.date("%H", timestamp))
    return lastHourUpdate == tonumber(os.date("%H"))
end

function QuickApp:getNumbers(value)
    if (value == nil) then return nil end
    local str = ""
    string.gsub(value, "%d+", function(e) str = str ..e end)
    return str
end

function QuickApp:getDecimals(value, includePoint)
    local x = tostring(value)
    local isDecimal = false
    local output = ""
    local startPoint = 0
    if (includePoint == nil or includePoint == true) then startPoint = 1 end

    for i = 1, string.len(x) do
        if isDecimal == false then
            if string.sub(x, i + startPoint, i + startPoint) == "." then
                isDecimal = true
            end
        else
            output = output ..string.sub(x, i, i)
        end
    end
    return output
end

function QuickApp:toDefault(value, default)
    if default == nil then default = "" end
    if value == nil or value == "nan" then return default end
    return value
end

-- Get ENTSO-e next day price release date in local time
function QuickApp:getRateReleaseTime(timezoneOffset, format)
    if timezoneOffset == nil then timezoneOffset = 0 end
    if format == nil then format = "!%H%M" end
    return os.date(format, os.time({year=2000, month=1, day=1, hour=self.nextday_releaseHourUtc, min=10}) + timezoneOffset)
end

function QuickApp:isTimeForNextDayRates()
    if (self.serviceSuccess == nil or self.timezoneOffset == nil or self.tariffAreaRates == nil) then return false end

    if (self.serviceSuccess and tonumber(os.date("%H%M", os.time())) >= tonumber(self:getRateReleaseTime(self.timezoneOffset, "!%H%M"))) then
        if (self:existsInEnergyTariffTable(self.tariffAreaRates, os.date("%Y%m%d", os.time() + 86400))) then return false end
        return true
    end
    return false
end

-- Count items in a Lua table
function QuickApp:tableCount(table)
    local count = 0
    if table == nil or table == "" then return count end
    for _ in pairs(table) do count = count + 1 end
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
function QuickApp:getXmlElement(xml, name)
    return xml:match("<"..name..">(.-)</"..name..">")
end

-- Calculate tariff rate
function QuickApp:calculateTariffRate(rawRate, exchRate, unit, tax, operator, losses, adjustment, dealer, grid)
    if (rawRate == nil) then rawRate = 0 end
    if (exchRate == nil or exchRate == 0) then exchRate = self.exchangeRate end
    if (tax == nil or tax == 0) then tax = 1 end
    if (tax > 1) then tax = (tax / 100) + 1 end -- Convert input tax from % to decimal if > 1
    if (operator == nil) then operator = 0 end
    if (losses == nil or losses == 0) then losses = 1 end
    if (losses > 1) then losses = (losses / 100) + 1 end -- Convert input losses in % to decimal if > 1
    if (adjustment == nil or adjustment == 0) then adjustment = 1 end
    if (adjustment > 1) then adjustment = (adjustment / 100) + 1 end -- Convert input adjustment in % to decimal if > 1
    if (dealer == nil) then dealer = 0 end
    if (grid == nil) then grid = 0 end

    -- Get Unit scale. ENTSO-e always return prices in €/MWh
    local unitScale = 1000 -- kWh
    if (unit == "MWh") then unitScale = 1 end 
    
    -- Recalculate main rate from EUR/mWh to {local currency}/{MWh or kWh} * tax
    local rate = string.format("%f", ((((((rawRate * exchRate) / unitScale) + operator) * losses * adjustment) + dealer + grid) * tax))
    return tonumber(rate)
end

function QuickApp:getRank(value)
    -- Set defaults if not valid input value
    if (value == nil or value == "nan" or value == "--") then return "" end
    value = tonumber(value)

    -- Return price rank from variable rank values
    local rank = "VeryLOW"
    if (value >= self.low_price) then rank = "LOW" end
    if (value >= self.medium_price) then rank = "MEDIUM" end
    if (value >= self.high_price) then rank = "HIGH" end
    if (value >= self.veryhigh_price) then rank = "VeryHIGH" end

    self:d("Set the rank level value " ..value .." = " ..rank)

    return rank
end

function QuickApp:getRankIcon(value)
    if (value == "VeryHIGH") then return "🔴" end
    if (value == "HIGH")     then return "🟠" end
    if (value == "MEDIUM")   then return "🟡" end
    if (value == "LOW")      then return "🔵" end
    if (value == "VeryLOW")  then return "🟢" end
    return "⛔" -- Wrong value
end

function QuickApp:getNextDirection(currentValue, nextValue)
    -- Examples ⬆️⬇️➡️ or ⇧⇨⇩
    if (currentValue == nil) then currentValue = 0 end
    if (nextValue == nil) then nextValue = 0 end
    if (currentValue > nextValue) then return "⬇️" end
    if (currentValue < nextValue) then return "⬆️" end
    return "➡️"
end
