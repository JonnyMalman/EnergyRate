-- Update FIBARO Tariff rate table
function QuickApp:updateFibaroTariffTable()
    -- Exit if no data in global table or we got Service error
    if (self:getGlobalFibaroVariable(self.global_var_fibaro_tariff_name, "ON") == "OFF" or self:tableCount(self.tariffAreaRates) == 0) then return end

    -- Get current FIBARO Energy Tariff rate data
    local tariffData = api.get("/energy/billing/tariff")
    local currRate = tariffData.rate
    local exchRate = self.exchangeRate
    local addTariffs = {}
    local currentRateTime = os.date("%Y%m%d%H")
    local count = 0

    -- Update FIBARO Additional Tariff table in local currency/kWh and local timezone
    for _, dateTariff in pairs(self.tariffAreaRates) do
        if (dateTariff == nil) then return end
        exchRate = dateTariff.exch

        for index, tariff in pairs(dateTariff.rates) do
            local time = index - 1
            local currTime = self:toDate(dateTariff.date, time, "%Y%m%d%H")
            local startTime = self:toDate(dateTariff.date, time, "%H:%M", 0)
            local endTime = self:toDate(dateTariff.date, time, "%H:%M", 1)
            local tariffName = self:toDate(dateTariff.date, time, self:getDateFormat(), 0) .." " ..startTime .." (" ..tariff[1] .." €/MWh)"

            -- Calculate to Local Tariff Rate price, FIBARO can only display prices in kWh
            local locRate = self:calculateTariffRate(tariff[1], exchRate, "kWh", self.tax, self.operatorCost, self.gridLosses, self.gridAdjustment, self.dealerCost, self.gridCost)

            -- FIBARO Tariff table can't have zero or negative value :(
            if (locRate <= 0) then
                tariffName = tariffName .." " ..string.format(self:getValueFormat(), locRate) .." ⛔"
                locRate = 0.00001
            end

            -- Get current rate
            if (currTime == currentRateTime) then 
                currRate = locRate
                tariffName = tariffName .." ⭐"
                self:d("Current energy price: "..tariff[1] .."=" ..currRate .." at exchange: " ..dateTariff.exch ..", Unit: " ..self.unit ..", Name: " ..tariffName)
            end
            
            -- Add additional tariff to local tariff table
            local newTariff = {
                name = tariffName,
                rate = locRate,
                startTime = startTime,
                endTime = endTime,
                days = {string.lower(self:toDate(dateTariff.date, time, "%A", 0))}
            }
            table.insert(addTariffs, newTariff)
            count = count + 1
        end
    end

    -- Save new tariff table to FIBARO Tariff table
    local response, code = api.put("/energy/billing/tariff", {
        returnRate = tariffData.returnRate,
        additionalTariffs = addTariffs,
        name = tariffData.name,
        rate = currRate
    })

    self:d(" => Update " ..count .." FIBARO Tariffs with response code: " .. tostring(code) .. " - \"" .. tariffData.name .. "\" Rate: " .. tariffData.rate .. " => " .. currRate)
end
