-- Exchange rates API (https://exchangerate.host) is a simple and lightweight free service for current and historical foreign exchange rates & crypto exchange rates.
-- Create free account at https://exchangerate.host to get an access key that will give you 1000 requests each month.

function QuickApp:getServiceExchangeRate(force)
    self.exchServiceMessage = ""

    if (self.currency == "EUR") then
        if (self.exchangeRate > 1) then 
            self:setVariable(self.var_exchange_rate_name, 0)
            self:setVariable(self.var_exchange_last_update_name, "")
        end
        self.exchangeRate = 1 -- Set default excahnge rate 1:1 for €
        self.exchangeRateUpdated = true
        return force
    end

    -- Check if we fulfill to request Exchangerate.host API
    if (self:isEmpty(self.exchangerate_Key)) then
        self.exchangeRateUpdated = false
        self.exchServiceMessage = "Local QA variable [" ..self.var_exchange_rate_Key_name .."] is required to get exchange rates between EUR and " ..self.currency ..".\nRegister a free account at https://exchangerate.host to get your own API access key."
        QuickApp:error(self.exchServiceMessage)
        return true
    end
    
    -- Check if we already have got the Exchange rate for today
    if (self:isNotEmpty(self.exchangeLastUpdate) and os.date("%Y-%m-%d") == self.exchangeLastUpdate) then
        self:d("Exchange rate for date " ..self.exchangeLastUpdate .." is already retrieved: 1 EUR = " ..tostring(self.exchangeRate) .." " ..self.currency)
        self.exchangeRateUpdated = true
        return force
    end

    -- Request exchangerate.host with source currency "EUR" that always is ENTSO-e base currency
    local url = self.exchangerate_baseURL .."live?access_key=" ..self.exchangerate_Key  .."&source=EUR&currencies=" ..self.currency

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
                self:d("Exchange Rate response: " ..json.encode(data))

                if (data.success == true) then
                    self.exchangeRateUpdated = true
                    self.exchangeLastUpdate = os.date("%Y-%m-%d", data.timestamp)
                    self:setVariable(self.var_exchange_last_update_name, self.exchangeLastUpdate)
                    
                    local cSymbol = "EUR" ..self.currency
                    self.exchangeRate = data.quotes[cSymbol]
                    self:setVariable(self.var_exchange_rate_name, self.exchangeRate)
                    self:d("Exchange Rate " ..os.date("%Y-%m-%d %H:%M", data.timestamp) ..": 1 EUR = " ..self.exchangeRate .." " ..self.currency)
                else
                    self.exchangeRateUpdated = false
                    self.exchServiceMessage = "Exchange rate error:\n" ..data.error.info
                    QuickApp:error("Error when request for exchange rate from Url: " ..url ..". " ..self.exchServiceMessage)
                end
            else
                self.exchangeRateUpdated = false
                QuickApp:error("Broken json response from Url: " ..url)
            end
        end,
        error = function(message)
            self.exchangeRateUpdated = false
            self.exchServiceMessage = "Exchange rate error: " ..message
            self.httpClient = net.HTTPClient()
            QuickApp:error(self.exchServiceMessage)
        end
    })
    return true
end
