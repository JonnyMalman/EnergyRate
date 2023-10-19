-- Load Energy Tariff table from FIBARO general variable 
function QuickApp:loadEnergyTariffTable()
    self.tariffData = {}
    self.tariffAreaRates = {}

    local jsonString = fibaro.getGlobalVariable(self.global_var_state_table_name)
    
    -- Create global variable if missing
    if (jsonString == nil) then self:createGlobalTableVariable() end

    -- Decode json string to table
    if (jsonString ~= nil and jsonString ~= "") then 
        self.tariffData = json.decode(jsonString)
    end

    -- Set local area tariff table
    if (self.areaName == nil or self.areaName == "" or self.currency == nil or self.currency == "") then return end
    self.tariffAreaRates = self.tariffData[self.areaName ..":" ..self.currency]
    if (self.tariffAreaRates == nil) then self.tariffAreaRates = {} end
end

-- Refresh Energy Tariff table
function QuickApp:refreshEnergyTariffTable()
    -- Get current day energy rates.
    self:getServiceRateData(QuickApp.updateEnergyTariffTable, self, os.date("%Y%m%d"), self.exchangeRate, true)

    -- Get next 24 hour energy rates if they have been released
    fibaro.setTimeout(2000, function() self:getNextDayTariffRates() end)
    
    -- Add additional energy rate date from QA variable "AddTariffDate"
    fibaro.setTimeout(4000, function() self:updateHistoryTariffRates() end)
end

-- Update Energy Tariff table
function QuickApp:updateEnergyTariffTable(energyRateTable)
    -- Exit if no data from ENTSO-e service
    if (energyRateTable == nil or self:tableCount(energyRateTable) == 0) then return end

    -- Set local variables
    if self.tariffHistory == nil then self.tariffHistory = 365 end
    local tariffHourHistory = self.tariffHistory
    local updateTable = false
    local areaTableId = self.areaName ..":" ..self.currency

    -- Load Energy Tariff Table    
    self:loadEnergyTariffTable()
    
    local tblCount = 0
    local dayRates = {}
    local exchRate = self.exchangeRate
    local tariffDate = os.date("%Y%m%d")

    -- Add ENTSO-e raw rates to Energy tariff table if not already exists
    local totalRate = 0;
    
    -- Loop ENTSO-e rates table and add to new Energy rates table
    for index, tariff in pairs(energyRateTable) do
        totalRate = totalRate + tariff.rate
        exchRate = tariff.exch
        tariffDate = tariff.date

        if not (self:existsInEnergyTariffTable(self.tariffAreaRates, tariff.date, index)) then
            table.insert(dayRates, {tariff.rate})
            updateTable = true
        end
    end

    -- If all rates in response table is 0 then not update Energy Tariff table, something is wrong!?
    if (updateTable and totalRate == 0) then
        self.serviceSuccess = false -- Something got wrong in ENTSO-e request
        QuickApp:error("Error in ENTSO-e Energy rate data!")
        return
    end
        
    -- Add new rates to Area Tariff table
    if (updateTable) then
        table.insert(self.tariffAreaRates, {date = tariffDate, exch = exchRate, rates = dayRates})
        tblCount = self:tableCount(self.tariffAreaRates)

        -- Sort tariff table by Id (DateTime)
        table.sort(self.tariffAreaRates, function (t1, t2) return t1.date < t2.date end )

        -- Update Energy tariff rates
        local updTariffs = {}
        local startIndex = 0

        -- Clean old Energy tartiff rates
        if (tariffHourHistory > 0 and tariffHourHistory < tblCount) then
            startIndex = tblCount - tariffHourHistory
        end

        -- Update Exchange rate and clean old history
        for index, tariff in pairs(self.tariffAreaRates) do
            if index > startIndex then
                if (tariff.exch == 0 and tariff.date == os.date("%Y%m%d")) then
                    self:d("Exchange rate updated: " ..tariff.exch .." => " ..self.exchangeRate)
                    tariff.exch = self.exchangeRate
                end
                table.insert(updTariffs, tariff)
            end
        end
        self.tariffAreaRates = updTariffs

        -- Save Energy tariff table to FIBARO general variable
        local areaTariffs = {}
        areaTariffs[areaTableId] = self.tariffAreaRates
        self.TariffData = areaTariffs
        fibaro.setGlobalVariable(self.global_var_state_table_name, json.encode(self.TariffData))

        self:d("Energy Tariff table updated: " ..tariffDate .." (Exch:" ..exchRate .."). Cleaned from " ..startIndex .." old history day(s)")
    end
end

-- Get Energy Tariff Data
function QuickApp:getEnergyRateData()
    -- Load Energy Tariff data from general variables if empty
    self:loadEnergyTariffTable()

    if self.tariffHistory == nil then self.tariffHistory = 365 end
    
    local energyPricesUpdated = false
    local nowFormat = "%H"               -- Local timezone "HH"
    local dayDate = os.date("%Y%m%d")    -- Local timezone "YYYYMMDD"
    local monthDate = os.date("%Y%m")    -- Local timezone "YYYYMM"
    local nextDayDate = os.date("%Y%m%d", os.time() + 86400)
    local oneHour = 1 * 60 * 60          -- 1 hour
    local previousRate = self.high_price -- Set default to High price
    local currentRate = nil  -- Set default to High price
    local nextRate = self.high_price     -- Set default to High price
    local dayRatesExists = false
    local totalCount = 0
    local totalRate = 0
    local totalDayCount = 0
    local totalDayRate = 0
    local totalMonthCount = 0
    local totalMonthRate = 0
    local minDayRate = 9999
    local maxDayRate = 0
    local totalNextDayCount = 0
    local totalNextDayRate = 0    
    local minNextDayRate = 9999
    local maxNextDayRate = 0
    local avgNextDayRate = 0
    local nextDayRate = false
    local firstIdDate = ""
    local lastIdDate = ""
    local exchRate = 0

    -- Sum each FIBARO tariff rate (Rate is in €/MWh and id is in local format "YYMMDDHH")
    local tblCount = self:tableCount(self.tariffAreaRates)
    if (tblCount > 0) then
        for _, dateTariff in pairs(self.tariffAreaRates) do
            if (dateTariff == nil) then return {} end
            
            for index, tariff in pairs(dateTariff.rates) do
                local time = index - 1
                if (dateTariff.exch > 0) then exchRate = dateTariff.exch end

                -- Set first and last id
                if firstIdDate == "" then firstIdDate = dateTariff.date end
                lastIdDate = dateTariff.date

                -- Calculate to Local Tariff Rate price
                local locRate = self:calculateTariffRate(tariff[1], exchRate, self.unit, self.tax, self.operatorCost, self.gridLosses, self.gridAdjustment, self.dealerCost, self.gridCost, self.allowNegative)

                -- Set total values
                totalRate = totalRate + locRate
                totalCount = totalCount + 1
                energyPricesUpdated = true

                -- Sum today values "YYYYMMDD"
                if (dateTariff.date == dayDate) then
                    totalDayRate = totalDayRate + locRate
                    totalDayCount = totalDayCount + 1
                    if locRate < minDayRate then minDayRate = locRate end
                    if locRate > maxDayRate then maxDayRate = locRate end
                    
                    -- Set previous, next and current rate values
                    if (time == tonumber(os.date(nowFormat, os.time() - oneHour))) then previousRate = locRate end
                    if (time == tonumber(os.date(nowFormat, os.time() + oneHour))) then nextRate = locRate end
                    if (time == tonumber(os.date(nowFormat, os.time())))           then currentRate = locRate end                    
                end
                
                -- Sum current month values "YYYYMM"
                if (string.sub(dateTariff.date, 1, 6) == monthDate) then
                    totalMonthRate = totalMonthRate + locRate
                    totalMonthCount = totalMonthCount + 1
                end

                -- Sum tomorrow values
                if (dateTariff.date == nextDayDate) then
                    totalNextDayRate = totalNextDayRate + locRate
                    totalNextDayCount = totalNextDayCount + 1
                    if locRate < minNextDayRate then minNextDayRate = locRate end
                    if locRate > maxNextDayRate then maxNextDayRate = locRate end
                end
            end
        end
    end

    -- Set minimum day rates to 0 if 9999
    if (minNextDayRate >= 9999) then minNextDayRate = 0 end
    if (minDayRate >= 9999) then minDayRate = 0 end
    
    -- Set if day rates exists
    if (totalDayCount > 0) then dayRatesExists = true end

    -- Calculate tomorrow average values
    if (totalNextDayCount > 0) then 
        avgNextDayRate = totalNextDayRate / totalNextDayCount 
        nextDayRate = true
    end

    -- Set current price if not exists
    local storeRate = tostring(currentRate)
    if (currentRate == nil) then
        currentRate = self.high_price
        storeRate = ""
    end

    -- Store current rate price to general variable
    fibaro.setGlobalVariable(self.global_var_current_rate_name, storeRate)

    -- Set return Tariff Data table
    local tariffData = {
        energyPricesUpdated = energyPricesUpdated,
        count = totalCount,
        previousRate = string.format(self.valueFormat, previousRate),
        currentRate = string.format(self.valueFormat, currentRate),
        nextRate = string.format(self.valueFormat, nextRate),
        dayRatesExists = dayRatesExists,
        avgTotalRate = self:toDefault(string.format(self.valueFormat, totalRate / totalCount), "0"),
        avgDayRate = self:toDefault(string.format(self.valueFormat, totalDayRate / totalDayCount), "0"),
        avgDayCount = totalDayCount,
        avgMonthRate = self:toDefault(string.format(self.valueFormat, totalMonthRate / totalMonthCount), "0"),
        avgMonthCount = totalMonthCount,
        minDayRate = string.format(self.valueFormat, minDayRate),
        maxDayRate = string.format(self.valueFormat, maxDayRate),
        nextDayRate = nextDayRate,
        avgNextDayRate = self:toDefault(string.format(self.valueFormat, avgNextDayRate), "0"),
        minNextDayRate = string.format(self.valueFormat, minNextDayRate),
        maxNextDayRate = string.format(self.valueFormat, maxNextDayRate),
        firstDate = self:toDate(firstIdDate, 0, "%Y-%m-%d"),
        lastDate = self:toDate(lastIdDate, 0, "%Y-%m-%d")
    }

    self:d("Energy tariff - Count: " ..tariffData.count .." (History " ..(self.tariffHistory) .." days), Previous Rate: " ..tariffData.previousRate ..", Current Rate: " ..tariffData.currentRate ..", next Rate: " ..tariffData.nextRate ..", Total avrage Rate: " ..tariffData.avgTotalRate)

    return tariffData
end

-- Get next 24 hour energy rates if they have been released, normally the next day energy rates are released after 12:00 UTC.
-- We also need the next day rates to solve the midnight shift between 23:00 and 00:00.
function QuickApp:getNextDayTariffRates()
    if (self:isTimeForNextDayRates()) then
        self:getServiceRateData(QuickApp.updateEnergyTariffTable, self, os.date("!%Y%m%d", os.time() + 86400), self.exchangeRate, false)

        self:debug("Get next 24 hour energy rates. (" ..tostring(self.serviceSuccess) ..") " ..os.date("%H:%M", os.time()) .." >= " ..self:getRateReleaseTime(self.timezoneOffset, "!%H:%M") .." (UTC: " ..os.date("!%Y-%m-%d", os.time() + 86400) ..") Exch: " ..tostring(self.exchangeRate))
    end
end

-- Update Tariff table with history rates
function QuickApp:updateHistoryTariffRates()
    -- Get date from local variable
    self.addTariffDate = self:getVariable(self.var_add_date_tariff_name)
    local addTariffDate = self:getNumbers(self.addTariffDate)

    if (self.serviceSuccess == false or addTariffDate == nil or addTariffDate == "" or addTariffDate == "0") then return end
    
    -- Get history Exchange rate from Exchangerate.host Api Service !! This not supported on Free account anymore !!
    --if (self.currency ~= "EUR") then -- If local currency already in Euro we don't need exchange rates.
    --    self:getServiceExchangeData(QuickApp.setExchangeRate, self, self:toDate(addTariffDate))
    --end

    fibaro.setTimeout(2000, function() 
        local exchHistRate = self.exchangeRate
        self:getServiceRateData(QuickApp.updateEnergyTariffTable, self, addTariffDate, exchHistRate, false)
        self:debug("Add extra energy tariff rates for date: " ..addTariffDate .." Exchange rate: 1 € = " ..exchHistRate .." " ..self.currency)

        self.addTariffDate = ""
        self:setVariable(self.var_add_date_tariff_name, dateString)
    end)
end

-- Check if rate already exists in Energy tariff table
function QuickApp:existsInEnergyTariffTable(table, date, index)
    self:d("Check if Tariff rate exists: " ..tostring(date) .. ", Index: " ..tostring(index) ..", " ..tostring(table))
    if table == nil or date == nil or date == "" then return false end
    
    for idx, tariff in pairs(table) do
        -- self:d("--> Rate: " ..tostring(date) .." = " ..tariff.date .." [" ..tostring(index) .."] = " ..idx)
        if (tariff.date == date and (index == nil or tariff.rates[index][1] ~= nil)) then
            self:d("Tariff rate for " ..date .." exists")
            return true
        end
    end

    return false
end
