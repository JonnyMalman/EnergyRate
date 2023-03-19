-- Exchange rates API is a simple and lightweight free service for current and historical foreign exchange rates & crypto exchange rates.
-- Reliable and up-to-date EU VAT rates, sourced directly from the European Commission's databases.
-- If you like it, donate a cappuccino https://exchangerate.host/#/donate ;)

-- Service home site: https://exchangerate.host

function QuickApp:setExchangeRate(responseData)
    if responseData == nil then
        self:debug("Exchange Rate: Error when request rate!")
    end

    for curr, value in pairs(responseData.rates) do
        self.exchangeRate = tonumber(value)
        self:d("Exchange Rate: 1 EUR = " .. value .. " " .. curr)
    end
end

function QuickApp:getServiceExchangeData(callback, instance)
    -- Request exchangerate.host with base currency "EUR" that always is ENTSO-e response currency
    local url = self.exchangerate_baseURL .. "latest?base=EUR&symbols=" .. self.currency .. "&amount=1"
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
                pcall(callback, instance, data)
            else
                self:debug("Broken json response from Url: " .. url)
                return nil
            end
        end,
        error = function(message)
            self:debug("Error:", message)
            return nil
        end
    })
end
