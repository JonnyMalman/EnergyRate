function QuickApp:updateEnergyTariffTable(energyRateTable)
    -- Exit if no data from ENTSO-e
    if self:tableCount(energyRateTable) == 0 then return end

    -- Set local variables
    if self.tariffHistory == nil then self.tariffHistory = 365 end
    local tariffHourHistory = self.tariffHistory * 24
    local updateTariff = false

    -- Get current Energy Tariff data from global variables if empty
    local tblCount = self:tableCount(self.tariffData[self.areaName])
    if (tblCount == 0) then self.tariffData = self:getEnergyTariffTable() end
    local areaRates = self.tariffData[self.areaName]
    if (areaRates == nil) then areaRates = {} end

    -- Add ENTSO-e raw rates to Energy tariff table if not already exists
    local totalRate = 0;
    
    for index, tariff in pairs(energyRateTable) do
        totalRate = totalRate + tariff.rate
        if not (self:existsInEnergyTariffTable(areaRates, tariff.id)) then
            table.insert(areaRates, tariff)
            updateTariff = true
            self:d("New ENTSO-e Energy rate added: " ..tariff.id .." = " ..tariff.rate)
        end
    end

    -- If all rates in response table is 0 then not update Energy Tariff table, something is wrong!?
    if (totalRate == 0) then
        self.serviceSuccess = false -- Something got wrong in ENTSO-e request
        self:d("Error in ENTSO-e Energy rate data!")
        return
    end

    -- Update Energy Tariff table if need to clean history
    if updateTariff then tblCount = self:tableCount(areaRates) end
    if (tblCount > tariffHourHistory) then updateTariff = true end

    -- Update Energy tariff rates with sorted and cleaned Tariff data
    if updateTariff then
        -- Sort tariff table by Id (DateTime)
        table.sort(areaRates, function (t1, t2) return t1.id < t2.id end )

        -- Clean old Energy tartiff rates
        if (tariffHourHistory > 0 and tariffHourHistory < tblCount) then
            local cleanTariffs = {}
            local startIndex = tblCount - tariffHourHistory
            for index, tariff in pairs(tariffRates) do
                if index > startIndex then
                    table.insert(cleanTariffs, tariff)
                end
            end
            areaRates = cleanTariffs
            self:d("Energy tariff table cleaned from old history: " ..startIndex .." hours")
        end

        -- Save Energy tariff table to FIBARO global variable
        self.tariffData[self.areaName] = areaRates
        fibaro.setGlobalVariable(self.global_var_state_table_name, json.encode(self.tariffData))
        self:d("Energy Tariff table updated in FIBARO global variables")
    end
end

function QuickApp:getEnergyRateData()
    -- Get current Energy Tariff data from global variables if empty
    local tblCount = self:tableCount(self.tariffData)
    if (tblCount == 0) then self.tariffData = self:getEnergyTariffTable() end
    local areaRates = self.tariffData[self.areaName]
    if areaRates == nil then areaRates = {} end

    if self.tariffHistory == nil then self.tariffHistory = 365 end
    
    local energyPricesUpdated = false
    local nowFormat = "%y%m%d%H"         -- Local timezone "YYMMDDHH"
    local dayDate = os.date("%y%m%d")    -- Local timezone "YYMMDD"
    local monthDate = os.date("%y%m")    -- Local timezone "YYMM"
    local nextDayDate = os.date("%y%m%d", os.time() + 86400)
    local oneHour = 1 * 60 * 60          -- 1 hour
    local previousRate = self.high_price -- Set default to High price
    local currentRate = self.high_price  -- Set default to High price
    local nextRate = self.high_price     -- Set default to High price
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

    -- Sum each FIBARO tariff rate (Rate is in €/MWh and id is in local format "YYMMDDHH")
    if (tblCount > 0) then
        for index, tariff in pairs(areaRates) do
            -- Set first and last id
            if index == 1 then firstIdDate = tariff.id end
            lastIdDate = tariff.id

            -- Calculate Local Tariff Rate
            local locRate = self:getLocalTariffRate(tariff.rate, self.exchangeRate, self.unit, self.tax, self.operatorCost, self.gridLosses, self.gridAdjustment, self.dealerCost, self.gridCost)

            -- Set total values
            totalRate = totalRate + locRate
            totalCount = totalCount + 1
            energyPricesUpdated = true

            -- Sum today values "YYMMDD"
            if (string.sub(tariff.id, 1, 6) == dayDate) then
                totalDayRate = totalDayRate + locRate
                totalDayCount = totalDayCount + 1
                if locRate < minDayRate then minDayRate = locRate end
                if locRate > maxDayRate then maxDayRate = locRate end
            end
            
            -- Sum current month values "YYMM"
            if (string.sub(tariff.id, 1, 4) == monthDate) then
                totalMonthRate = totalMonthRate + locRate
                totalMonthCount = totalMonthCount + 1
            end

            -- Sum tomorrow values
            if (string.sub(tariff.id, 1, 6) == nextDayDate) then
                totalNextDayRate = totalNextDayRate + locRate
                totalNextDayCount = totalNextDayCount + 1
                if locRate < minNextDayRate then minNextDayRate = locRate end
                if locRate > maxNextDayRate then maxNextDayRate = locRate end
            end

            -- Set previous, current and next rate values
            if (tariff.id == os.date(nowFormat, os.time() - oneHour)) then previousRate = locRate end
            if (tariff.id == os.date(nowFormat, os.time()))           then currentRate = locRate end
            if (tariff.id == os.date(nowFormat, os.time() + oneHour)) then nextRate = locRate end
        end
    end

    -- Set minimum day rates to 0 if 9999
    if (minNextDayRate >= 9999) then minNextDayRate = 0 end
    if (minDayRate >= 9999) then minDayRate = 0 end
    
    -- Calculate tomorrow average values
    if (totalNextDayCount > 0) then 
        avgNextDayRate = totalNextDayRate / totalNextDayCount 
        nextDayRate = true
    end

    -- Set return Tariff Data table
    local tariffData = {
        energyPricesUpdated = energyPricesUpdated,
        count = totalCount,
        previousRate = string.format(self.valueFormat, previousRate),
        currentRate = string.format(self.valueFormat, currentRate),
        nextRate = string.format(self.valueFormat, nextRate),
        avgTotalRate = self:toDefault(string.format(self.valueFormat, totalRate / totalCount)),
        avgDayRate = self:toDefault(string.format(self.valueFormat, totalDayRate / totalDayCount)),
        avgDayCount = totalDayCount,
        avgMonthRate = self:toDefault(string.format(self.valueFormat, totalMonthRate / totalMonthCount)),
        avgMonthCount = totalMonthCount,
        minDayRate = string.format(self.valueFormat, minDayRate),
        maxDayRate = string.format(self.valueFormat, maxDayRate),
        nextDayRate = nextDayRate,
        avgNextDayRate = self:toDefault(string.format(self.valueFormat, avgNextDayRate)),
        minNextDayRate = string.format(self.valueFormat, minNextDayRate),
        maxNextDayRate = string.format(self.valueFormat, maxNextDayRate),
        firstDate = self:toDate(firstIdDate, "%Y-%m-%d"),
        lastDate = self:toDate(lastIdDate, "%Y-%m-%d")
    }

    self:d("Energy tariff - Count: " ..tariffData.count .." (History " ..(self.tariffHistory * 24) .." h), Previous Rate: " ..tariffData.previousRate ..", Current Rate: " ..tariffData.currentRate ..", next Rate: " ..tariffData.nextRate ..", Total avrage Rate: " ..tariffData.avgTotalRate)

    return tariffData
end

function QuickApp:IsEnergyTariffUpToDate()
    local tblCount = self:tableCount(self.tariffData[self.areaName])
    if (tblCount == 0) then return false end

    if self.tariffHistory == nil then self.tariffHistory = 365 end
    local tariffHourHistory = self.tariffHistory * 24
    local dateFormat = "%y%m%d%H"
    local oneHour = 1 * 60 * 60        -- 1 hour
    local nextDayShift = 24 * 60 * 60  -- 24 hours
    local keepHistory = false
    local previousExists = false
    local currentExist = false
    local nextExists = false
    local nextDayExists = true

    if (tblCount > tariffHourHistory) then 
        self:d("Energy tariff table need to be cleaned!")
        return false
    end

    -- ENTSO-e relese next day energy rate prices after 12:00 UTC each day
    if (tonumber(os.date("%H", os.time())) >= self:getRateReleaseTime(self.timezoneOffset)) then nextDayExists = false end

    -- Check FIBARO Tariff if all rates already exists
    for _, tariff in pairs(self.tariffData[self.areaName]) do
        if (tariff.id == os.date(dateFormat, os.time() - oneHour))      then previousExists = true end
        if (tariff.id == os.date(dateFormat, os.time()))                then currentExist = true end
        if (tariff.id == os.date(dateFormat, os.time() + oneHour))      then nextExists = true end
        if (tariff.id == os.date(dateFormat, os.time() + nextDayShift)) then nextDayExists = true end
        
        if previousExists and currentExist and nextExists and nextDayExists then
            self:d("Energy tariff table is already up to date")
            return true
        end   
    end

    self:d("Energy tariff table need to be updated!")
    return false
end

-- Check if rate already exists in Energy tariff table
function QuickApp:existsInEnergyTariffTable(rates, match)
    if rates == nil then return false end
    for index, data in pairs(rates) do
        if (tostring(data.id) == tostring(match)) then return true end
    end
    self:d("Energy tariff id " ..match .." not exists!")
    return false
end
