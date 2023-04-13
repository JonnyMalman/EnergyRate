function QuickApp:displayEnergyRate()   
    -- Get current Fibaro Tariff Data
    local tariffData = self:getFibaroTariffData()
    
    -- Calculate values
    local rank = self:getRank(tariffData.currentRate)
    local nextRank = self:getRank(tariffData.nextRate)
    local nextDir = self:getNextDirection(tariffData.currentRate, tariffData.nextRate)
    local prevDir = self:getNextDirection(tariffData.previousRate, tariffData.currentRate)
    local rateDiff = string.format("%.2f", tonumber(tariffData.nextRate - tariffData.currentRate))
    local prevDiff = string.format("%.2f", tonumber(tariffData.currentRate - tariffData.previousRate))

    -- Set dafaults
    local avgRate = 0
    local avgRank = ""
    local refresh = "♻️"
    local lastRqt = refresh ..self.i18n:get("LoadingEnergyRates") .."️..."
    local lastUpd = refresh ..self.i18n:get("Refreshing") .."️..."
    local areaName = self.areaName

    -- Set Exchange rate
    local exchangeRate = "--"
    if (self.exchangeRate > 0) then exchangeRate = self.exchangeRate end

    -- If Service request failed
    if not self.serviceSuccess then
        lastRqt = "n/a"
        lastUpd = "n/a"
        areaName = areaName .."\n⚠️ " ..self.i18n:get("MissingEnergyRatesForSelectedArea")
        if (self.serviceMessage ~= "") then areaName = areaName .."\n⛔ " ..self.serviceMessage .."\n" end
    end

    -- Only update variables and tariff if we got "real" rate data
    if tariffData.count > 0 then 
        avgTotalRank = self:getRank(tariffData.avgTotalRate)
        avgDayRank = self:getRank(tariffData.avgDayRate)
        avgMonthRank = self:getRank(tariffData.avgMonthRate)

        refresh = ""

        self:updateProperty('value', tonumber(tariffData.currentRate))
        self:updateProperty('log', self:getRankIcon(rank) ..rank)
        fibaro.setGlobalVariable(self.global_var_level_name, rank)        
        fibaro.setGlobalVariable(self.global_var_next_level_name, nextRank)
        fibaro.setGlobalVariable(self.global_var_month_level_name, avgMonthRank)
        fibaro.call(self.next_rank_device_id, 'setLog', self:getRankIcon(nextRank) ..nextRank)
        fibaro.call(self.next_rank_device_id, 'setUnit', " " .. nextDir)
        fibaro.call(self.next_rank_device_id, 'setValue', rateDiff)

        lastUpd = os.date("%Y-%m-%d %H:%M")
        self:updateView("refreshButton", "text", self.i18n:get("Refresh"))
        
        self:d("Display panels updated: " ..os.date("%H:%M:%S"))
    end

    -- Update FIBARO Info panel
          local labelInfo = self.i18n:get("TodayRates") .." (" ..self.i18n:get("Range") ..": " ..tariffData.minDayRate .." " ..self.i18n:get("To") .." " ..tariffData.maxDayRate .." " ..self.currency ..")\n"
    labelInfo = labelInfo ..self:getRankIcon(rank) .." " ..self.i18n:get("CurrentHour") ..": " ..tariffData.currentRate .." " ..self.currency .." (" ..prevDiff .." " ..prevDir ..") - " ..self.i18n:get(rank) .."\n"
    labelInfo = labelInfo ..self:getRankIcon(nextRank) .." " ..self.i18n:get("NextHour") ..": " ..tariffData.nextRate .." " ..self.currency .." (" ..rateDiff .." " ..nextDir ..") - " ..self.i18n:get(nextRank) .."\n"
    labelInfo = labelInfo ..self:getRankIcon(avgDayRank) .." " ..self.i18n:get("TodayAverage") ..": " .. tariffData.avgDayRate .." " ..self.currency .." - " ..self.i18n:get(avgDayRank) .."\n\n"

    if (tariffData.avgNextDayRate == nil) then
        labelInfo = labelInfo ..self.i18n:get("TomorrowRatesReleases") .." " ..self:getRateReleaseTime(self.timezoneOffset) ..":00 (UTC: " ..self.nextday_releaseTime ..":00)\n"
        labelInfo = labelInfo .."🕓 " ..self.i18n:get("TomorrowAverage") ..": --\n\n"
    else
        local avgNextDayRank = self:getRank(tariffData.avgNextDayRate)
        labelInfo = labelInfo ..self.i18n:get("TomorrowRateRange") ..": " ..tariffData.minNextDayRate .." " ..self.i18n:get("To") .." " ..tariffData.maxNextDayRate .." " ..self.currency .."\n"
        labelInfo = labelInfo ..self:getRankIcon(avgNextDayRank) .." " ..self.i18n:get("TomorrowAverage") ..": " ..tariffData.avgNextDayRate .." " ..self.currency .." - " ..self.i18n:get(avgNextDayRank) .."\n\n"
    end

    labelInfo = labelInfo ..self.i18n:get("TariffRatePeriod") ..": " ..string.sub(tariffData.firstRate, 1, 10) .." -- " ..string.sub(tariffData.lastRate, 1, 10) .."\n"
    labelInfo = labelInfo ..self:getRankIcon(avgMonthRank) .." " ..self.i18n:get("ThisMonthAverage") .. ": " ..tariffData.avgMonthRate .." " ..self.currency .." (" ..string.format("%.0f", tariffData.avgMonthCount/24) .." " ..self.i18n:get("Days") ..")\n"
    labelInfo = labelInfo ..self:getRankIcon(avgTotalRank) .." " ..self.i18n:get("TotalTariffAverage") .. ": " ..tariffData.avgTotalRate .." " ..self.currency .." (" ..string.format("%.0f", tariffData.count/24) .." "  ..self.i18n:get("Days") ..")" .."\n"

    labelInfo = labelInfo .."\n"
    labelInfo = labelInfo ..self.i18n:get("EnergyArea") ..": " ..areaName .."\n"
    labelInfo = labelInfo ..self.i18n:get("AreaCode") ..": " ..self.areaCode .."\n"
    labelInfo = labelInfo ..self.i18n:get("TariffRateHistory") ..": " ..self.tariffHistory .." " ..self.i18n:get("days") .."\n"
    labelInfo = labelInfo ..self.i18n:get("MediumRatePrice") ..": " ..self.mediumPrice .." " ..self.currency .."/kWh\n"

    labelInfo = labelInfo .."\n"
    labelInfo = labelInfo ..self.i18n:get("EnergyRateUpdate") ..": " ..self.serviceRequestTime .."\n"
    labelInfo = labelInfo ..self.i18n:get("VariableUpdate") ..": " ..lastUpd .."\n"

    -- Only show if exchange currency is not in Euro
    if (self.currency ~= "EUR") then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo ..refresh ..self.i18n:get("ExchangeRate") ..": 1 EUR = " .. exchangeRate .. " " .. self.currency
    end

    -- Only show if Tax is set
    if (self.tax > 0) then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo ..refresh ..self.i18n:get("Tax") ..": " ..string.format("%.0f", self.tax) .."%"
    end

    -- If missing translation, just to trigger users to help me with translations ;)
    if not (self.i18n.isTranslated) then
        labelInfo = labelInfo .."\n"
        labelInfo = labelInfo .."⚠️ " ..self.i18n:get("MissingTranslation") ..": " ..self.i18n.languageCode
    end

    self:updateView("labelInfo", "text", labelInfo)

    self:d("Current (" ..self.i18n:get(rank) ..") Rate: " ..tariffData.currentRate .." " ..self.currency .."/kWh" ..", Next (" ..nextRank ..") Rate: " ..tariffData.nextRate ..self.currency .."/kWh" .." (" ..rateDiff ..nextDir ..")")
end
