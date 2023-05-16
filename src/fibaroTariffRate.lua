-- Update FIBARO Tariff rate table
function QuickApp:updateFibaroTariffTable()
    -- Exit if no data in global table or we got Service error
    if (self:getGlobalFibaroVariable(self.global_var_fibaro_tariff_name, "ON") == "OFF" or self:tableCount(self.tariffData[self.areaName]) == 0 or self.serviceSuccess == false) then return end

    -- Get current FIBARO Energy Tariff rate data
    local tariffData = api.get("/energy/billing/tariff")
    local currRate = tariffData.rate
    local addTariffs = {}
    local currentRateTime = os.date("%y%m%d%H")
    local count = 0

    -- Update FIBARO Additional Tariff table in local currency/kWh and local timezone
    for index, tariff in pairs(self.tariffData[self.areaName]) do
        local startTime = self:toDate(tariff.id, "%H:%M", 0)
        local endTime = self:toDate(tariff.id, "%H:%M", 1)
        local tariffName = self:toDate(tariff.id, self:getDateFormat(), 0) .." " ..startTime .." (" ..tariff.rate .." €/MWh)"

        -- FIBARO only display price in kWh
        local locRate = self:getLocalTariffRate(tariff.rate, self.exchangeRate, "kWh", self.tax, self.operatorCost, self.gridLosses, self.gridAdjustment, self.dealerCost, self.gridCost)

        -- FIBARO Tariff table can't have negative values :(
        if (locRate <= 0) then
            tariffName = tariffName .." " ..string.format(self:getValueFormat(), locRate) .." ⛔"
            locRate = 0.00001
        end

        -- Get current rate
        if (tariff.id == currentRateTime) then 
            currRate = locRate
            tariffName = tariffName .." ⭐"
            self:d("Current energy price: "..tariff.rate .."=" ..currRate .." at exchange: " ..self.exchangeRate .." Unit: " ..self.unit .." ID: " ..tariff.id .." - " ..tariffName)
        end
        
        -- Add additional tariff to local tariff table
        local newTariff = {
            name = tariffName,
            rate = locRate,
            startTime = startTime,
            endTime = endTime,
            days = {string.lower(self:toDate(tariff.id, "%A", 0))}
        }
        table.insert(addTariffs, newTariff)
        count = count + 1
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
