-- Exchange rates API is a simple and lightweight free service for current and historical foreign exchange rates & crypto exchange rates.
-- Reliable and up-to-date EU VAT rates, sourced directly from the European Commission's databases.
-- If you like it, donate a cappuccino https://exchangerate.host/#/donate ;)

-- Service home site: https://exchangerate.host

function QuickApp:setExchangeRate(responseData)
    if responseData == nil then return end

    local exchRate = tonumber(responseData.rates[self.currency])
    if (responseData.date == os.date("%Y-%m-%d")) then
        self.exchangeRate = exchRate
        self.exchangeRateLastDate = responseData.date
    else -- If history rate
        self.exchangeHistoryRate = exchRate
    end

    self:d("Exchange Rate " ..responseData.date ..": 1 EUR = " ..self.exchangeRate .." " ..self.currency)
end

function QuickApp:getServiceExchangeData(callback, instance, date)
    -- Check if we already have got the Exchange rate for today
    if ((date == nil or date == "") and (self.exchangeRateLastDate ~= nil or self.exchangeRateLastDate ~= "") and os.date("%Y-%m-%d") == self.exchangeRateLastDate) then
        self:d("Exchange rate for date " ..self.exchangeRateLastDate .." is already retrieved: 1 EUR = " ..tostring(self.exchangeRate) .." " ..self.currency)
        return nil
    end

    -- Request exchangerate.host with base currency "EUR" that always is ENTSO-e response currency
    local url = self.exchangerate_baseURL .."latest?base=EUR&symbols=" ..self.currency .."&amount=1"
    if (date ~= nil and date ~= "") then url = self.exchangerate_baseURL ..date .."&base=EUR&symbols=" ..self.currency .."&amount=1" end

    self.httpClient:request(url, {
        options = {
            method = "GET",
            headers = {["Accept"] = "application/json"}
        },
        success = function(response)
            local success, data = pcall(function()
                                            return json.decode(response.data)
                                        end)

            if success then
                self.exchangeRateUpdated = true
                self.dataChanged = true
                pcall(callback, instance, data)
            else
                self.exchangeRateUpdated = false
                self:debug("Broken json response from Url: " ..url)
                return nil
            end
        end,
        error = function(message)
            self.exchangeRateUpdated = false
            self.serviceMessage = "ExchangeRate Error: " ..message
            self:debug(self.serviceMessage)
            self.httpClient = net.HTTPClient()
            return nil
        end
    })
end
