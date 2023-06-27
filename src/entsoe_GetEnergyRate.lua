-- https://transparency.entsoe.eu/content/static_content/Static%20content/web%20api/Guide.html#_generation_domain
-- 4.2.10. Day Ahead Rates [12.1.D]

function QuickApp:getServiceRateData(callback, instance, date, exchRate, reportError)
    -- ENTSO-e service only returns 24 hour Rates on each request even if we define another "to Date" :(
    if (date == nil or date == "") then
        self:d("Missing date when request ENTSO-e rate service")
        return nil 
    end

    -- Don´t request ENTSO-e service if we already have the requested energy rates in table
    if (self:existsInEnergyTariffTable(self.tariffAreaRates, date)) then
        self:d("ENTSO-e rate already exists for date: " ..date .." (Exch: " ..tostring(exchRate) ..")")
        self.serviceSuccess = true
        return nil
    end
        
    -- Set current Exchange rate if missing or 0 if nextday
    if (exchRate == nil) then exchRate = self.exchangeRate end
    if (tonumber(date) > tonumber(os.date("%Y%m%d"))) then exchRate = 0 end

    -- Request ENTO-e service
    self:d("Request ENTSO-e for period UTC: " ..date .."0000 -- " ..date .."2300 (AreaCode: " ..self.areaCode ..") Exch: " ..tostring(exchRate))
    local ratePrices = {}
    local rateTable = {}
    local url = self.entsoe_baseURL .."?documentType=A44&in_Domain=" ..self.areaCode .."&out_Domain=" ..self.areaCode .."&periodStart=" ..date .."0000&periodEnd=" ..date .."2300&securityToken=" ..self.token

    self.httpClient:request(url, {
        options = {
            method = "GET",
            headers = {
                ["SECURITY_TOKEN"] = self.token,
                ["Accept"] = "text/xml"
            }
        },
        success = function(response)
            -- Create Rate table from XML response
            local periodXml = self:getXmlElement(response.data, "Period")
            local success, data = pcall(function()
                                            return self:xml2PriceTable(periodXml) -- Extact rate prices from XML
                                        end)                                        
            if success then
                if data == nil then
                    if (reportError == true) then
                        self.serviceSuccess = false
                        self.serviceMessage = "ERROR: Empty response from Url " ..url
                        self:debug(self.serviceMessage)
                    end
                    return nil
                end

                -- Get UTC start and end date from response XML
                local startDate = self:getXmlDate(periodXml, "start", "%Y-%m-%d %H:%M")
                local endDate = self:getXmlDate(periodXml, "end", "%Y-%m-%d %H:%M")

                -- Create local date and rate table
                for index, rate in pairs(data) do
                    local localDate = self:toLocalDate(startDate, self.timezoneOffset, "%Y%m%d")
                    local ratePrice = {
                        date = localDate,
                        exch = exchRate,
                        rate = tonumber(rate)
                    }
                    table.insert(ratePrices, ratePrice)
                end

                self.serviceRequestTime = os.date(self:getDateFormat()) .." " ..os.date("%H:%M")
                self.serviceSuccess = true
                self.serviceMessage = ""
                self.dataChanged = true
                self:d("=> ENTSO-e Success response: Start UTC = " .. startDate .. ", End UTC = " .. endDate .. ", " .. self:tableCount(ratePrices) .. " rates")
                
                pcall(callback, instance, ratePrices)
            else
                if (reportError == true) then
                    self.serviceSuccess = false
                    self.serviceMessage = "Error: Can't get energy rates from ENTSO-e for area: " ..self.areaName
                    self:debug(self.serviceMessage)
                end
                return nil
            end
        end,
        error = function(message)
            if (reportError == true) then
                self.serviceSuccess = false
                self.serviceMessage = "ENTSO-e Error: " ..message
                self:debug(self.serviceMessage)
                self.httpClient = net.HTTPClient()
            end
            return nil
        end
    })
end

-- Extract ENTSO-e prices from response xml into Lua table
function QuickApp:xml2PriceTable(xml)
    local priceTable = {}
    local ni, c, label, xarg, empty
    local i, j = 1, 1

    while true do
        ni, j, c, label, xarg, empty = string.find(xml, "<(%/?)([%w:_]+)(.-)(%/?)>", i)
        if not ni then break end
        local text = string.sub(xml, i, ni-1)
   
        if not string.find(text, "^%s*$") and label == "price" then
            table.insert(priceTable, text)
        end

        i = j+1
    end

    return priceTable
end
