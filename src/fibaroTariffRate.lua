function QuickApp:updateFibaroTariffTable(energyRateTable)
    -- Exit if no data
    if self:tableCount(energyRateTable) == 0 then return end
    if self.tariffHistory == nil then self.tariffHistory = 365 end

    -- Get current FIBARO Energy Tariff data
    local tariffData = api.get("/energy/billing/tariff")
    local tariff = {}
    local addTariffs = tariffData.additionalTariffs
    local tblCount = self:tableCount(addTariffs)
    local rate = tariffData.rate
    local updateTariff = false
    local maxHoursInTariff = self.tariffHistory * 24
    
    -- If reset Tariff rates button have been pressed
    if (updateTariff) then
        addTariffs = {}
        self:d("Reset FIBARO Tariff rates!")
    end

    -- Create Additional Tariff table in kWh/local currency and timezone
    for index, rateData in pairs(energyRateTable) do
        local tariffName = self:getRateDate(rateData.rateDate, "%Y-%m-%d %H:%M", 0, self.timezoneOffset)

        if updateTariff or not (self:existsInFibaroTariffTable(addTariffs, tariffName)) then
            tariff = {
                name = tariffName,
                rate = self:getLocalTariffRate(rateData.rate, self.exchangeRate),
                startTime = self:getRateDate(rateData.rateDate, "%H:%M", 0, self.timezoneOffset),
                endTime = self:getRateDate(rateData.rateDate, "%H:%M", 1, self.timezoneOffset),
                days = {string.lower(self:getRateDate(rateData.rateDate, "%A", 0, self.timezoneOffset))}
            }
            table.insert(addTariffs, tariff)
            updateTariff = true
        end
    end
   
   -- Update FIBARO Tariff table if need to clean history
   if (tblCount > maxHoursInTariff) then updateTariff = true end

    -- Update FIBARO tariff rates with new Tariff data
    if updateTariff then       
        -- Sort tariff table by name (DateTime)
        table.sort(addTariffs, function (t1, t2) return t1.name < t2.name end )

        -- Clean old Tartiff rates
        if (maxHoursInTariff > 0 and maxHoursInTariff < tblCount) then
            local cleanTariffs = {}
            local startIndex = tblCount - maxHoursInTariff
            for index, tariff in pairs(addTariffs) do
                if index > startIndex then
                    table.insert(cleanTariffs, tariff)
                end
            end
            addTariffs = cleanTariffs
            self:d("Tariff table clean from old history: " ..startIndex .." hours")
        end

        -- Get current rate from FIBARO Tariff rates
        local currentTariff = self:getFibaroTariff(addTariffs, os.date("%Y-%m-%d %H:00", os.time()))
        if (currentTariff ~= nil) then
            if (rate ~= currentTariff.rate) then updateTariff = true end
            rate = currentTariff.rate
            self:d("Set new Tariff rate: " ..rate .." " ..self.currency)
        end    

        local response, code = api.put("/energy/billing/tariff", {
            returnRate = tariffData.returnRate,
            additionalTariffs = addTariffs,
            name = tariffData.name,
            rate = rate
        })

        self:d("Update Tariff response " .. tostring(code) .. " - \"" .. tariffData.name .. "\" Rate: " .. tariffData.rate .. " => " .. rate .. " (TimezoneOffset: " .. self.timezoneOffset .. ")")
    end
end

function QuickApp:getFibaroTariffData()
    -- Get current FIBARO Energy Tariff data
    local tariffData = api.get("/energy/billing/tariff")

    local dateFormat = "%Y-%m-%d %H:00"
    local dayDate = os.date("%Y-%m-%d")
    local nextDayDate = os.date("%Y-%m-%d", os.time() + 86400)
    local monthDate = os.date("%Y-%m")
    local timeShift = 1 * 60 * 60  -- 1 hours
    local previousRate = 0
    local currentRate = 0
    local nextRate = 0
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
    local avgNextDayRate = nil
    local first = ""
    local last = ""

    -- TODO: Get AvgDay, AvgTotal, AvgComming, AvgMonth
    -- For each FIBARO tariff rates
    if (self:tableCount(tariffData.additionalTariffs) > 0) then
        for index, tariff in pairs(tariffData.additionalTariffs) do
            -- Set first and last name
            if index == 1 then first = tariff.name end
            last = tariff.name

            -- Set total values
            totalRate = totalRate + tariff.rate
            totalCount = totalCount + 1

            -- Set today values
            if (string.sub(tariff.name, 1, 10) == dayDate) then
                totalDayRate = totalDayRate + tariff.rate
                totalDayCount = totalDayCount + 1
                if tariff.rate < minDayRate then minDayRate = tariff.rate end
                if tariff.rate > maxDayRate then maxDayRate = tariff.rate end
            end
            
            -- Set current month values
            if (string.sub(tariff.name, 1, 7) == monthDate) then
                totalMonthRate = totalMonthRate + tariff.rate
                totalMonthCount = totalMonthCount + 1
            end

            -- Set tomorrow values
            if (string.sub(tariff.name, 1, 10) == nextDayDate) then
                totalNextDayRate = totalNextDayRate + tariff.rate
                totalNextDayCount = totalNextDayCount + 1
                if tariff.rate < minNextDayRate then minNextDayRate = tariff.rate end
                if tariff.rate > maxNextDayRate then maxNextDayRate = tariff.rate end
            end

            -- Set previous, current and next rate values
            if (tariff.name == os.date(dateFormat, os.time() - timeShift))    then previousRate = tariff.rate end
            if (tariff.name == os.date(dateFormat, os.time()))                then currentRate = tariff.rate end
            if (tariff.name == os.date(dateFormat, os.time() + timeShift))    then nextRate = tariff.rate end
        end

        -- Calculate tomorrow average values
        if (totalNextDayCount > 0) then avgNextDayRate = string.format("%.2f", tonumber(totalNextDayRate / totalNextDayCount)) end

        -- Update FIBARO tariff rate with current rate if not same
        if (tariffData.rate ~= currentRate) then
            local response, code = api.put("/energy/billing/tariff", {
                returnRate = tariffData.returnRate,
                additionalTariffs = tariffData.additionalTariffs,
                name = tariffData.name,
                rate = currentRate
            })

            self:d("Update Tariff response " .. tostring(code) .. " - \"" .. tariffData.name .. "\" Rate: " .. tariffData.rate .. " => " .. currentRate)
        end
    end

    -- Set return Tariff Data table
    local tariffData = {
        count = totalCount,
        previousRate = previousRate,
        currentRate = currentRate,
        nextRate = nextRate,
        avgTotalRate = string.format("%.2f", tonumber(totalRate / totalCount)),
        avgDayRate = string.format("%.2f", tonumber(totalDayRate / totalDayCount)),
        avgDayCount = totalDayCount,
        avgMonthRate = string.format("%.2f", tonumber(totalMonthRate / totalMonthCount)),
        avgMonthCount = totalMonthCount,
        minDayRate = minDayRate,
        maxDayRate = maxDayRate,
        avgNextDayRate = avgNextDayRate,
        minNextDayRate = minNextDayRate,
        maxNextDayRate = maxNextDayRate,        
        firstRate = first,
        lastRate = last
    }

    self:d("TariffData - Count: " ..tariffData.count .." (" ..(self.tariffHistory * 24) .."), Previous Rate: " ..tariffData.previousRate ..", Current Rate: " ..tariffData.currentRate ..", next Rate: " ..tariffData.nextRate ..", Total avrage Rate: " ..tariffData.avgTotalRate)

    return tariffData
end

function QuickApp:IsFibaroTariffUpToDate()
    -- Get current FIBARO Energy Tariff data
    local tariffData = api.get("/energy/billing/tariff")

    if self.tariffHistory == nil then self.tariffHistory = 365 end
    local maxHoursInTariff = self.tariffHistory * 24
    local tblCount = self:tableCount(tariffData.additionalTariffs)
    local dateFormat = "%Y-%m-%d %H:00"
    local timeShift = 1 * 60 * 60      -- 1 hours
    local nextDayShift = 24 * 60 * 60  -- 24 hours
    local keepHistory = false
    local previousExists = false
    local currentExist = false
    local nextExists = false
    local nextDayExists = true

    if (tblCount > maxHoursInTariff) then 
        self:d("FIBARO Tariff rate panel need to be cleaned!")
        return false
    end

    -- ENTSO-e relese next day energy rate prices after 12:00 UTC each day
    if (tonumber(os.date("!%H", os.time())) >= 12) then nextDayExists = false end

    for _, tariff in pairs(tariffData.additionalTariffs) do
        if (tariff.name == os.date(dateFormat, os.time() - timeShift))    then previousExists = true end
        if (tariff.name == os.date(dateFormat, os.time()))                then currentExist = true end
        if (tariff.name == os.date(dateFormat, os.time() + timeShift))    then nextExists = true end
        if (tariff.name == os.date(dateFormat, os.time() + nextDayShift)) then nextDayExists = true end
        
        if previousExists and currentExist and nextExists and nextDayExists then
            self:d("FIBARO Tariff rate panel is already up to date")
            return true
        end   
    end

    self:d("FIBARO Tariff rate panel need to be updated!")
    return false
end

function QuickApp:existsInFibaroTariffTable(table, match)
    for _, data in pairs(table) do
        if (data.name == match) then return true end
    end
    self:d("Fibaro Tariff " ..match .." not exists!")
    return false
end

function QuickApp:getFibaroTariff(rates, match)
    for _, data in pairs(rates) do
        if (data.name == match) then return data end
    end
    self:d("Fibaro Tariff " ..match .." is missing!")
    return nil
end
