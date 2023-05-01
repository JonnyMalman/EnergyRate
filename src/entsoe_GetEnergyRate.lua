-- https://transparency.entsoe.eu/content/static_content/Static%20content/web%20api/Guide.html#_generation_domain
-- 4.2.10. Day Ahead Rates [12.1.D]

function QuickApp:getServiceRateData(callback, instance, fromdate, todate, reportError)
    self:d("Request ENTSO-e for period UTC: " .. fromdate .. " -- " .. todate .. " (AreaCode: " .. self.areaCode .. ")")

    local ratePrices = {}
    local url = self.entsoe_baseURL .. "?documentType=A44&in_Domain=" .. self.areaCode .. "&out_Domain=" .. self.areaCode .. "&periodStart=" .. fromdate .. "&periodEnd=" .. todate .. "&securityToken=" .. self.token

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

                -- Create (UTC) date and rate table
                for index, rate in pairs(data) do
                    local ratePrice = {
                        id = self:toLocalDateId(startDate, index - 1, self.timezoneOffset),
                        rate = tonumber(rate)
                    }
                    table.insert(ratePrices, ratePrice)
                end

                self:d("=> Response: Start UTC = " .. startDate .. ", End UTC = " .. endDate .. ", " .. self:tableCount(ratePrices) .. " rates")
                
                self.serviceSuccess = true
                self.serviceMessage = ""

                pcall(callback, instance, ratePrices)
            else
                if (reportError == true) then
                    self.serviceSuccess = false
                    self.serviceMessage = "Error: Can't get energy prices from ENTSO-e"
                    self:debug(self.serviceMessage)
                end
                return nil
            end
        end,
        error = function(message)
            if (reportError == true) then
                self.serviceSuccess = false
                self.serviceMessage = "Error: " ..message
                self:debug(self.serviceMessage)
            end
            return nil
        end
    })
end