-- https://transparency.entsoe.eu/content/static_content/Static%20content/web%20api/Guide.html#_generation_domain
-- 4.2.10. Day Ahead Rates [12.1.D]

function QuickApp:getServiceRateData(callback, instance, fromdate, todate)
    self:d("Request ENTSO-e for period UTC: " .. fromdate .. " -- " .. todate .. " (AreaCode: " .. self.areaCode .. ")")

    local ratePrice = {}
    local ratePrices = {}
    local rateTable = {}
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
                                            return self:xml2PriceTable(periodXml)
                                        end)                                        
            if success then
                if data == nil then 
                    self.serviceSuccess = false
                    self.serviceMessage = "ERROR: Empty response from Url " ..url
                    self:debug(self.serviceMessage)
                    return nil
                end

                -- Get UTC start and end date from response XML
                local startDate = self:getXmlDate(periodXml, "start", "%Y-%m-%d %H:%M")
                local endDate = self:getXmlDate(periodXml, "end", "%Y-%m-%d %H:%M")

                -- Create (UTC) date and rate table
                for index, rate in pairs(data) do
                    ratePrice = {
                        rateDate = self:getRateDate(startDate, "%Y-%m-%d %H:%M", index - 1),
                        rateTime = self:getRateDate(startDate, "%d.%H", index - 1),
                        rate = rate
                    }
                    table.insert(ratePrices, ratePrice)
                end

                self:d("=> Response: Start UTC = " .. startDate .. ", End UTC = " .. endDate .. ", " .. self:tableCount(ratePrices) .. " rates")
                
                self.serviceSuccess = true
                self.serviceMessage = "" 
                pcall(callback, instance, ratePrices)
            else
                self.serviceSuccess = false
                self.serviceMessage = "Error: Can't access ENTSO-e or current Token is not valid!"
                self:debug(self.serviceMessage)
                return nil
            end
        end,
        error = function(message)
            self.serviceSuccess = false
            self.serviceMessage = "Error: " ..message
            self:debug(self.serviceMessage)
            return nil
        end
    })
end
