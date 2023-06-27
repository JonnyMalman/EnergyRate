function QuickApp:displayEnergyRate()   
    -- ENTSO-e Energy Area not selected
    if self.areaCode == nil or self.areaCode == "" then
        self:updateView("labelInfo", "text", "\n💡 " ..self.i18n:get("NoSelectedArea") .."\n\n\n")
        self:updateView("refreshButton", "text", "⚠️  " ..self.i18n:get("Refresh") .."  ⚠️")
        self:d("No EnergyArea selected!")
        return
    end

    -- Get current Fibaro Tariff Data
    local tariffData = self:getEnergyRateData()
    
    -- Calculate values
    local rank = self:getRank(tariffData.currentRate)
    local nextRank = self:getRank(tariffData.nextRate)
    local nextDir = self:getNextDirection(tariffData.currentRate, tariffData.nextRate)
    local prevDir = self:getNextDirection(tariffData.previousRate, tariffData.currentRate)
    local rateDiff = string.format(self.valueFormat, tariffData.nextRate - tariffData.currentRate)
    local prevDiff = string.format(self.valueFormat, tariffData.currentRate - tariffData.previousRate)

    -- Set dafaults
    local labelInfo = ""
    local avgRate = 0
    local avgRank = ""
    local refresh = "♻️"
    local serviceUpdated = refresh
    local lastRqt = refresh ..self.i18n:get("LoadingEnergyRates") .."️..."
    local lastUpd = "(" ..tostring(self.lastVariableUpdate) ..") " ..refresh ..self.i18n:get("Refreshing") .."️..."    
    local areaName = self.areaName
    local areaCode = self.areaCode

    -- Set Exchange rate
    local exchangeRate = "--"
    if (self.exchangeRate ~= nil) then exchangeRate = string.format(self.valueFormat, self.exchangeRate) end

    -- Show if any service error
    if (self.serviceMessage ~= "") then labelInfo = "⛔ " ..self.serviceMessage .."\n\n" end

    -- If Service request failed
    if self.serviceSuccess == false then
        refresh = "⚠️"
        lastUpd = tostring(self.lastVariableUpdate)
        serviceUpdated = "--"
        areaName = self.areaName .."\n" ..refresh .." " ..self.i18n:get("MissingEnergyRatesForSelectedArea")
    end

    -- Only update variables and tariff if we got "real" rate data
    if tariffData.energyPricesUpdated == true and self.exchangeRateUpdated == true then
        avgTotalRank = self:getRank(tariffData.avgTotalRate)
        avgDayRank = self:getRank(tariffData.avgDayRate)
        avgMonthRank = self:getRank(tariffData.avgMonthRate)
        
        -- Update FIBARO general variables 
        fibaro.setGlobalVariable(self.global_var_level_name, rank)        
        fibaro.setGlobalVariable(self.global_var_next_level_name, nextRank)
        fibaro.setGlobalVariable(self.global_var_month_level_name, avgMonthRank)

        -- Update QA with current hour price
        self:updateProperty('value', tonumber(tariffData.currentRate))
        self:updateProperty('log', self:getRankIcon(rank) ..rank)

        -- Update child QA with next hour price
        if (self.next_rank_device_id ~= nil) then
            fibaro.call(self.next_rank_device_id, 'setUnit', self:getDecimals(rateDiff, true) .." " ..nextDir)
            fibaro.call(self.next_rank_device_id, 'setValue', math.floor(math.abs(rateDiff)))
            fibaro.call(self.next_rank_device_id, 'setLog', self:getRankIcon(nextRank) ..nextRank)
        end
        
        serviceUpdated = self.serviceRequestTime
        self.lastVariableUpdate = os.date("%Y-%m-%d %H:%M")
        self.dataChanged = false
        lastUpd = self.lastVariableUpdate
        refresh = ""
        
        self:d("Display panels updated: " ..os.date("%Y-%m-%d %H:%M:%S"))
    end

    -- Update FIBARO Info panel
    if (tariffData.dayRatesExists == false) then
        labelInfo = labelInfo .."⚠️ " ..self.i18n:get("TodayRatesMissing") .."\n"
        labelInfo = labelInfo ..self.i18n:get("CurrentHour") .." --\n"
        labelInfo = labelInfo ..self.i18n:get("NextHour") .." --\n"
        labelInfo = labelInfo ..self.i18n:get("TodayAverage") .." --\n\n"
    else
        labelInfo = labelInfo ..self.i18n:get("TodayRates") .." (" ..self.i18n:get("Range") ..": " ..tariffData.minDayRate .." ~ " ..tariffData.maxDayRate .." " ..self:getCurrencySymbol() ..")\n"
        labelInfo = labelInfo ..self:getRankIcon(rank) .." " ..self.i18n:get("CurrentHour") ..": " ..tariffData.currentRate .." " ..self:getCurrencySymbol() .." (" ..prevDiff .." " ..prevDir ..") - " ..self.i18n:get(rank) .."\n"
        labelInfo = labelInfo ..self:getRankIcon(nextRank) .." " ..self.i18n:get("NextHour") ..": " ..tariffData.nextRate .." " ..self:getCurrencySymbol() .." (" ..rateDiff .." " ..nextDir ..") - " ..self.i18n:get(nextRank) .."\n"

        labelInfo = labelInfo ..self:getRankIcon(avgDayRank) .." " ..self.i18n:get("TodayAverage") ..": " .. tariffData.avgDayRate .." " ..self:getCurrencySymbol() .." - " ..self.i18n:get(avgDayRank) .."\n\n"
    end

    if (tariffData.nextDayRate == true) then
        local avgNextDayRank = self:getRank(tariffData.avgNextDayRate)
        labelInfo = labelInfo ..self.i18n:get("TomorrowRateRange") ..": " ..tariffData.minNextDayRate .." ~ " ..tariffData.maxNextDayRate .." " ..self:getCurrencySymbol() .."\n"
        labelInfo = labelInfo ..self:getRankIcon(avgNextDayRank) .." " ..self.i18n:get("TomorrowAverage") ..": " ..tariffData.avgNextDayRate .." " ..self:getCurrencySymbol() .." - " ..self.i18n:get(avgNextDayRank) .."\n\n"
    else
        --labelInfo = labelInfo ..self.i18n:get("TomorrowRatesReleases") .." ~" ..self:getRateReleaseTime(self.timezoneOffset, "!%H:%M") .."\n"
        labelInfo = labelInfo .."🕓 " ..self.i18n:get("TomorrowAverage") ..": --\n\n"
    end

    labelInfo = labelInfo ..self.i18n:get("TariffRatePeriod") ..": " ..tariffData.firstDate .." -- " ..tariffData.lastDate .."\n"
    labelInfo = labelInfo ..self:getRankIcon(avgMonthRank) .." " ..self.i18n:get("ThisMonthAverage") .. ": " ..tariffData.avgMonthRate .." " ..self:getCurrencySymbol() .." (" ..string.format("%.0f", tariffData.avgMonthCount/24) .." " ..self.i18n:get("Days") ..")\n"
    labelInfo = labelInfo ..self:getRankIcon(avgTotalRank) .." " ..self.i18n:get("TotalTariffAverage") .. ": " ..tariffData.avgTotalRate .." " ..self:getCurrencySymbol() .." (" ..string.format("%.0f", tariffData.count/24) .." "  ..self.i18n:get("Days") ..")" .."\n"

    labelInfo = labelInfo .."\n"
    labelInfo = labelInfo ..self.i18n:get("LowRatePrice") ..": " ..self.low_price .." ~ " ..self.medium_price .." " ..self:getCurrencySymbol() .."/" ..self.unit .."\n"
    labelInfo = labelInfo ..self.i18n:get("MediumRatePrice") ..": " ..self.medium_price .." ~ " ..self.high_price .." " ..self:getCurrencySymbol() .."/" ..self.unit .."\n"
    labelInfo = labelInfo ..self.i18n:get("HighRatePrice") ..": " ..self.high_price .." ~ " ..self.veryhigh_price .." " ..self:getCurrencySymbol() .."/" ..self.unit .."\n"

    labelInfo = labelInfo .."\n"
    labelInfo = labelInfo ..self.i18n:get("EnergyArea") ..": " ..areaName .."\n"
    --labelInfo = labelInfo ..self.i18n:get("AreaCode") ..": " ..areaCode .."\n" -- This is unnecessary information
    labelInfo = labelInfo ..self.i18n:get("TariffRateHistory") ..": " ..self.tariffHistory .." " ..self.i18n:get("days") .."\n"
    labelInfo = labelInfo ..self.i18n:get("FibaroTariff") ..": " ..fibaro.getGlobalVariable(self.global_var_fibaro_tariff_name) .."\n"
    
    labelInfo = labelInfo .."\n"
    labelInfo = labelInfo ..self.i18n:get("EnergyRateUpdate") ..": " ..serviceUpdated .."\n"
    labelInfo = labelInfo ..self.i18n:get("VariableUpdate") ..": " ..lastUpd .."\n"

    -- Only show if Tax value is set
    if (self.tax ~= nil and self.tax ~= 0) then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo ..refresh ..self.i18n:get("Tax") ..": " ..string.format("%.2f", self.tax) .."%"
    end

    -- Only show if Operator value is set
    if (self.operatorCost ~= 0) then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo ..refresh ..self.i18n:get("OperatorCost") ..": " ..self.operatorCost .." " ..self:getCurrencySymbol() .."/"..self.unit
    end
    -- Only show if Losses value is set
    if (self.gridLosses ~= 0) then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo ..refresh ..self.i18n:get("GridLosses") ..": " ..string.format("%.2f", self.gridLosses) .."%"
    end
    -- Only show if Adjustment value is set
    if (self.gridAdjustment ~= 0) then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo ..refresh ..self.i18n:get("GridAdjustment") ..": " ..string.format("%.2f", self.gridAdjustment) .."%"
    end
    -- Only show if Dealer value is set
    if (self.dealerCost ~= 0) then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo ..refresh ..self.i18n:get("DealerCost") ..": " ..self.dealerCost .." " ..self:getCurrencySymbol() .."/"..self.unit
    end
    -- Only show if Grid value is set
    if (self.gridCost ~= 0) then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo ..refresh ..self.i18n:get("GridCost") ..": " ..self.gridCost .." " ..self:getCurrencySymbol() .."/"..self.unit
    end

    -- Only show if exchange currency is not in Euro
    if (self.currency ~= "EUR") then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo ..self.i18n:get("ExchangeRate") .." " ..self.exchangeRateLastDate ..": 1 € = " ..exchangeRate .." " ..self.currency --.."\n"
        --labelInfo = labelInfo ..self.i18n:get("ExchangeRateLastUpdate") ..": " ..self.exchangeRateLastDate
    end
    
    -- If missing translation, just to trigger users to help me with translations ;)
    if not (self.i18n.isTranslated) then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo .."💡 "..self.i18n:get("MissingTranslation") ..": " ..self.i18n.languageCode
    end

    self:updateView("labelInfo", "text", labelInfo)
    self:updateView("refreshButton", "text", self.i18n:get("Refresh"))

    self:d("Current (" ..self.i18n:get(rank) ..") Rate: " ..tariffData.currentRate .." " ..self.currency .."/kWh, Next (" ..nextRank ..") Rate: " ..tariffData.nextRate .." " ..self.currency .."/kWh" .." (" ..rateDiff ..nextDir ..")")
end
