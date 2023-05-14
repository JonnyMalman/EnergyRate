-- Write to console if debug=true
function QuickApp:d(msg)
    if self.debugOn then self:debug(msg) end
end

-- Get Energy Tariff table from global variable
function QuickApp:getEnergyTariffTable()
    local tariffData = {}
    local jsonString = fibaro.getGlobalVariable(self.global_var_state_table_name)
    
    -- Create global variable if missing
    if (jsonString == nil) then self:createGlobalVariableTable() end

    -- Decode json string to table
    if (jsonString ~= nil and jsonString ~= "") then 
        tariffData = json.decode(jsonString)
    end

    return tariffData
end

-- Get currency symbol
function QuickApp:getCurrencySymbol()
    local currency = self.currency
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

function QuickApp:toLocalDateId(dateString, addHour, timezoneOffset)
    if dateString == "" then return "" end
    if addHour == nil then addHour = 0 end
    if timezoneOffset == nil then timezoneOffset = 0 end
    -- Convert input dateString = "2022-12-25 23:00" to table Id date "22122523"
    local iyear, imonth, iday, ihour, iminute = dateString:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    local timestamp = os.time({year = iyear, month = imonth, day = iday, hour = ihour, min = iminute}) + timezoneOffset
    return os.date("%y%m%d%H", timestamp + (addHour * 60 * 60))
end

function QuickApp:toDate(dateId, format, addHour)
    if dateId == nil or dateId == "" then return "" end
    if format == nil then format = "%Y-%m-%d %H:%M" end
    if addHour == nil then addHour = 0 end
    -- Convert input dateId = "22122523" to Lua date format
    local iyear, imonth, iday, ihour = dateId:match("^(%d%d)(%d%d)(%d%d)(%d%d)$")
    local timestamp = os.time({year = iyear + 2000, month = imonth, day = iday, hour = ihour, min = iminute})
    return os.date(format, timestamp + (addHour * 60 * 60))
end

function QuickApp:updatePanel(dateString)
    if dateString == nil or dateString == "" then return true end

    -- Convert input dateString = "2022-12-25 23:00:00" to hour
    local iyear, imonth, iday, ihour, iminute, isec = dateString:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    local timestamp = os.time({year = iyear, month = imonth, day = iday, hour = ihour, min = iminute, sec = isec})
    local lastHourUpdate = tonumber(os.date("%H", timestamp))

    return lastHourUpdate ~= tonumber(os.date("%H"))
end

function QuickApp:toDefault(value)
    if value == nil or value == "nan" then return "0" end
    return value
end

-- Get ENTSO-e next day price release date in local time
function QuickApp:getRateReleaseTime(timezoneOffset)
    if timezoneOffset == nil then timezoneOffset = 0 end
    return tonumber(os.date("!%H", os.time({year=2000, month=1, day=1, hour=self.nextday_releaseTime, min=0}) + timezoneOffset))
end

-- Count items in a Lua table
function QuickApp:tableCount(T)
    local count = 0
    if T == nil or T == "" then return count end
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

function QuickApp:getLocalTariffRate(rawRate, exchangeRate, unit, tax, operator, losses, adjustment, dealer, grid)
    if (exchangeRate == nil) then exchangeRate = 1 end
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
    local rate = string.format("%f", ((((((rawRate * exchangeRate) / unitScale) + operator) * losses * adjustment) + dealer + grid) * tax))
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
    if (value == "HIGH") then return "🟠" end
    if (value == "MEDIUM") then return "🟡" end
    if (value == "LOW") then return "🔵" end
    if (value == "VeryLOW") then return "🟢" end
    return "⛔" -- Wrong value
end

function QuickApp:getNextDirection(currentValue, nextValue)
    -- ⬆️⬇️➡️ or ⇧⇨⇩
    if (currentValue == nil) then currentValue = 0 end
    if (nextValue == nil) then nextValue = 0 end
    if (currentValue > nextValue) then return "⬇️" end
    if (currentValue < nextValue) then return "⬆️" end
    return "➡️"
end
