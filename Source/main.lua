--[[
    ENTSO-e Energy Rate is an FIBARO QuickApp that get current Spot prices for almost every european countries and is independent from any energy power company for free.

    How to get your own Token:
    I´ve provide an Token that works "out of the box", but can be changed in the future, so if you like you can create your own free token at ENTSO-e, but not required.
    Register an ENTSO-e account at: https://transparency.entsoe.eu/
    How to get an Token: https://transparency.entsoe.eu/content/static_content/download?path=/Static%20content/API-Token-Management.pdf

    The Exchange rate service (https://exchangerate.host) that is used in this QuickApp to get your local currency is also free to use and if you like it, donate a cappuccino at https://exchangerate.host/#/donate ;)

    This is the first time I have developed in Lua language, so have some indulgence, but hey it works and I hope it works for U 2 ;)
    I would appreciate if you have any feedback or suggestions to make this QuickApp more usefull, please send me an email at energyrate@jamdata.com and I´ll try to do my best :)

    Changelog:
    v1.0 First release 2023-01
    v1.1 New feature release 2023-03
        - Keeps Tariff rate history in FIBARO.
        - Show more usefull info in QA panel.
        - Add new global month avrage level variable "EnergyMonthLevel" for those that pay energy consumtion per month avrage.
        - Add new QA variable "TariffHistory" for how many days to store history in FIBARO tariff rates.
        - Localized panel text for language: EN, DK, NO, SV (if you want to help me with translation, please send me an email at energyrate@jamdata.com)

        Braking changes that you need to change in your scenes if your using first release v1.0:
            Global variable name change from "EnergyRateArea" to "EnergyArea".
            Global variable name change from "EnergyRateMedium" to "EnergyMediumPrice".
            Global variable name change from "EnergyRateLevel" to "EnergyHourLevel".
            Global variable name change from "EnergyRateNextLevel" to "EnergyNextHourLevel".
]]

function QuickApp:onInit()
    self.debugOn = false -- Write to debug console true/false
    self.httpClient = net.HTTPClient()
    
    -- Variables for exchangerate.host Api service
    -- https://exchangerate.host
    self.exchangerate_baseURL = "https://api.exchangerate.host/"
    self.exchangeRate = 0

    -- Variables for ENTSO-e Transparency Platform Api service
    -- https://transparency.entsoe.eu/content/static_content/Static%20content/web%20api/Guide.html
    self.entsoe_baseURL = "https://web-api.tp.entsoe.eu/api"
    self.default_entsoe_token = "f442d0b3-450b-46d7-b752-d8d692fdb2c8" -- See "How to get your own Token:"
    self.default_area_name = "Sweden (SE3)"
    self.default_medium_price = "0.2"  -- 0,2 EUR/kWh
    self.default_tariff_history = "62" -- Default ~2 month
    self.child_rank_name = "ENTSO-e Next Energy Rate"
    self.next_rank_device_id = nil
    self.variable_token_name = "ENTSOE_Token"
    self.variable_tariff_history_name = "TariffHistory"
    self.global_var_area_name = "EnergyArea"    
    self.global_var_medium_price_name = "EnergyMediumPrice"
    self.global_var_level_name = "EnergyHourLevel"
    self.global_var_next_level_name = "EnergyNextHourLevel"
    self.global_var_month_level_name = "EnergyMonthLevel"

    self.serviceRequestTime = "--"  -- Last datetime when we request ENTSO-e webservice.
    self.serviceSuccess = true

    -- Let´s start
    self:mainStart()
end

function QuickApp:mainStart()
    self:refreshVariables()

    -- Create global varaiables and set default values (See: defaults)
    self:createGlobalVariables()
    self:createAreaVariables()
    self:setDefaultVariables()
            
    -- Init Child device to display next hour rate in Fibaro (See: QAChild_NextRank)
    self:initChildDevices({["com.fibaro.multilevelSensor"] = ENTSOE_Next_Rank})
    self:validateChildren()
    
    -- Start loop, one for request ENTSO-e service and exchange rate and one for updating global variables and panel display.
    self:d(">>>> Start ENTSO-e Energy Rate <<<<")
    self:serviceRequestLoop(false) -- Request ExchangeRate and ENTSO-e serices
end

-- Trigger if panel button pressed
function QuickApp:refresh_action()
    self:d("Execute ENTSO-e service update on button event...")
    self:updateView("refreshButton", "text", "⌛ " ..self.i18n:get("Refreshing") .."...")
    self:serviceRequestLoop(true)
end

-- ENTSO-e and Exchange rate service loop
function QuickApp:serviceRequestLoop(forceUpdate)
    -- Set Update service request loop to every hour
    local loopTime = (tonumber(os.date("%M"))) * 60 * 1000
   
     -- Refresh variable values
    self:refreshVariables()

    -- Get current Exchange rate from Exchangerate.host Api Service
    self:getServiceExchangeData(QuickApp.setExchangeRate, self)
    
    -- Check if table is already up to date, otherwise request service and update table  
    if forceUpdate or not self:IsFibaroTariffUpToDate() then               
        -- Get Energy Rates from ENSO-e Service (wait 2 sec for Exchange rate http request to complete)
        fibaro.setTimeout(2000, function() self:updateTariffData() end)
    end

    -- Start this Service request loop
    fibaro.setTimeout(loopTime, function() self:serviceRequestLoop() end)

    -- Update variables and panel
    self:displayLoop(true) 
end

function QuickApp:updateTariffData()
    -- Get current day energy rates.
    -- ENTSO-e service only returns 24 hour Rates on each request even if we define another "toDate" :(
    self:getServiceRateData(QuickApp.updateFibaroTariffTable, self, os.date("!%Y%m%d0000"), os.date("!%Y%m%d2300"))

    -- Get next 24 hour energy rates if they have been released, normally the next day energy rates are released after 12:00 UTC.
    -- We also need the next day rates to solve the midnight shift between 23:00 and 00:00.
    if (self.serviceSuccess and tonumber(os.date("!%H", os.time())) >= 12) then
        fibaro.setTimeout(2000, function() 
                                    self:getServiceRateData(QuickApp.updateFibaroTariffTable, self, os.date("!%Y%m%d0000", os.time() + 86400), os.date("!%Y%m%d2300", os.time() + 86400)) 
                                end)
    end
    
    self.serviceRequestTime = os.date("%Y-%m-%d %H:%M")
end

-- Variables and panel update display loop
function QuickApp:displayLoop(first)
    -- Set Update display loop to every full hour + 1 min
    local loopTime = 10000
    if not first then loopTime = (61 - tonumber(os.date("%M"))) * 60 * 1000 end

     -- Refresh variable values
    self:refreshVariables()
    
    -- Set Energy rates data to display
    self:displayEnergyRate()

    -- Start this display loop each hour
    fibaro.setTimeout(loopTime, function() self:displayLoop(false) end)
end
