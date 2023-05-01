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
        - Add new global month average level variable "EnergyMonthLevel" for those that pay energy consumtion per month average.
        - Add new QA variable "TariffHistory" for how many days to store history in FIBARO tariff rates.
        - Localized panel text for language: EN, DK, NO, SV (if you want to help me with translation, please send me an email at energyrate@jamdata.com)

        Braking changes that you need to change in your scenes if your using first release v1.0:
            Global variable name change from "EnergyRateArea" to "EnergyArea".
            Global variable name change from "EnergyRateMedium" to "EnergyMediumPrice".
            Global variable name change from "EnergyRateLevel" to "EnergyHourLevel".
            Global variable name change from "EnergyRateNextLevel" to "EnergyNextHourLevel".

    v1.2 Customer wishes release 2023-04
        - Option to add tax to the energy price.
        - Show if service error message.

    v1.3 Customer improvements 2023-05
        - Rewrite energy tariff table to store in global variable instead of FIBARO tariff table to solve negative energy prices.
        - Correct UTC time when request next day energy prices from ENTSO-e.
        - Improved energy value display formatting, with price decimal local variable, also show correct price if very low or negative price. (Except FIBARO tariff that can't show negative values)
        - All the rate levels are now set as local variables in real local energy price.
        - Removed the global variable "EnergyMediumPrice", medium price is now set between Low and High prices in QA variables.
        - Move global variable "EnergyTaxPercentage" to local variable as "EnergyTax".
        - Add global variable ON/OFF to store prices in FIBARO Tariff rate table.
        - Add translation in Portuguese (Thanks to Leandro C.).
        - New variables to cost calculation formula: {[(ENTSO_cost + deviation cost) x losses x adjustment] + dealer + localgrid} x tax (Leandro C.).
]]

function QuickApp:onInit()
    self.debugOn = false -- Write to debug console true/false
    self.httpClient = net.HTTPClient()
    
    -- Variables for exchangerate.host Api service
    -- https://exchangerate.host
    self.exchangerate_baseURL = "https://api.exchangerate.host/"
    self.exchangeRate = 1       -- Set default excahnge rate 1:1 for €

    -- Variables for ENTSO-e Transparency Platform Api service
    -- https://transparency.entsoe.eu/content/static_content/Static%20content/web%20api/Guide.html
    self.entsoe_baseURL = "https://web-api.tp.entsoe.eu/api"
    self.child_rank_name = "ENTSO-e Next Energy Rate"                   -- Name of next energy price QA child
    self.next_rank_device_id = nil                                      -- Id of next energy price QA child

    -- NOTE! Local QA variable names can only have maximun of 15 charachters
    self.variable_token_name = "ENTSOE_Token"
    self.variable_tariff_history_name = "TariffHistory"
    self.variable_Low_name = "PriceLow"
    self.variable_Medium_name = "PriceMedium"
    self.variable_High_name = "PriceHigh"
    self.variable_VeryHigh_name = "PriceVeryHigh"
    self.variable_tax_percentage_name = "EnergyTax"
    self.variable_price_decimals_name = "PriceDecimals"                 -- Variable name of number of decimals when display energy prices

    self.variable_operator_cost_name = "OperatorCost"                   -- Variable name of Grid Operator deviation costs (€/kWh or €/MWh)
    self.variable_grid_losses_name = "GridLossesPct"                    -- Variable name of Grid Losses percent cost (%)
    self.variable_grid_adjustment_name = "AdjustmentPct"                -- Variable name of Grid Adjustment percent cost added to the Grid Losses (%)
    self.variable_dealer_cost_name = "DealerFee"                        -- Variable name of Dealer fee cost (€/KWh or €/MWh)
    self.variable_grid_cost_name = "LocalGridCost"                      -- Variable name of Local Grid cost (€/KWh or €/MWh)

    -- Global variable names
    self.global_var_unit_name = "EnergyUnit"                            -- Global variable name of energy unit (KWh or MWh)
    self.global_var_state_table_name = "EnergyStateTable"               -- Global variable name of energy state table
    self.global_var_area_name = "EnergyArea"
    self.global_var_level_name = "EnergyHourLevel"
    self.global_var_next_level_name = "EnergyNextHourLevel"
    self.global_var_month_level_name = "EnergyMonthLevel"
    self.global_var_fibaro_tariff_name = "EnergyTariffInFibaro"
    
    -- Default values to set if missing
    self.default_token = "f442d0b3-450b-46d7-b752-d8d692fdb2c8"         -- See "How to get your own Token:" above.
    self.default_area_name = "Sweden (SE3)"                             -- Could not come up with better default then my Area :)
    self.default_unit = "kWh"                                           -- Show kWh or MWh in display panel (FIBARO Tariff table is always in kWh)
    self.default_tax = "0"                                              -- Default 0% energy tax
    self.default_tariff_history = "62"                                  -- Default 62 days ~2 month

    self.default_decimals = self:getDefaultPriceDecimals()              -- Get default number of decimals based on currency for prices display
    self.default_Low_price = self:getDefaultRatePrice(10)               -- 10% of medium price based on local currency
    self.default_High_price = self:getDefaultRatePrice(160)             -- 160% of medium price based on local currency
    self.default_VeryHigh_price = self:getDefaultRatePrice(250)         -- 250% of medium price based on local currency
    
    self.default_operator_cost = "0"                                    -- Default Grid Operator costs (0 €/kWh or 0 €/MWh)
    self.default_grid_losses = "0"                                      -- Default Grid Losses in percent (0 %)
    self.default_grid_adjustment = "0"                                  -- Default adjustment added to the Grid Losses in percent (0 %)
    self.default_dealer_cost = "0"                                      -- Default Dealer cost (0 €/KWh or 0 €/MWh)
    self.default_grid_cost = "0"                                        -- Default Local Grid cost (0 €/KWh or 0 €/MWh)

    -- Fixed QA variables
    self.nextday_releaseTime = 12                                       -- The UTC time of the day when ENTSO-e usually releses the next day prices
    self.dateFormat = self:getDateFormat()                              -- The FIBARO Date format setting ("YY-MM-DD", "DD.MM.YY" or "MM/DD/YY") that will be converted to Lua date format
    self.valueFormat = self:getValueFormat(self.default_decimals)       -- The value formatting of decimals when display Energy prices ie. "%.2f"
    self.serviceRequestTime = "--"                                      -- Last datetime when we request ENTSO-e webservice.
    self.serviceSuccess = true                                          -- Request ENTSO-e service success or fault
    self.serviceMessage = ""                                            -- Request ENTSO-e service error message
    
    -- Let´s start
    self:mainStart()
end

function QuickApp:mainStart()
    -- Create global varaiables and set default values (See: defaults)
    self:createAreaVariables()    
    self:createGlobalVariables()
    self:setLocalVariables()
            
    -- Init Child device to display next hour rate in FIBARO (See: QAChild_NextRank)
    self:initChildDevices({["com.fibaro.multilevelSensor"] = ENTSOE_Next_Rank})
    self:validateChildren()
    
    -- Start loop, one for request ENTSO-e service and exchange rate and one for updating global variables and panel display.
    self:d(">>>> Start ENTSO-e Energy Rate <<<<")
    self:serviceRequestLoop(false) -- Request ExchangeRate and ENTSO-e services
end

-- Trigger if panel refresh button pressed
function QuickApp:refresh_action()
    self:d("Execute ENTSO-e service update on button event...")
    self:updateView("refreshButton", "text", "⌛ " ..self.i18n:get("Refreshing") .."...")
    self:serviceRequestLoop(true)
end

-- ENTSO-e and Exchange rate service loop
function QuickApp:serviceRequestLoop(forceUpdate)
    -- Set Update service request loop to every hour
    local loopTime = (tonumber(os.date("%M"))) * 60 * 1000
   
    -- Get current Exchange rate from Exchangerate.host Api Service
    local waitTime = 0
    self.exchangeRateUpdated = true
    if (self.currency ~= "EUR") then -- If local currency already in Euro we don't need exchange rates.
        self:getServiceExchangeData(QuickApp.setExchangeRate, self)
        waitTime = 2000
    end

    -- Refresh variables
    self:refreshVariables()

    -- Check if table is already up to date, otherwise request service and update table  
    if forceUpdate or not self:IsEnergyTariffUpToDate() then
        -- Get Energy Rates from ENSO-e Service (only wait 2 sec for Exchange rate http request to complete if currency not in EUR)
        fibaro.setTimeout(waitTime, function() self:updateTariffData() end)
    end

    -- Start this Service request loop
    fibaro.setTimeout(loopTime, function() self:serviceRequestLoop() end)

    -- Update variables and panel
    self:displayLoop(true) 
end

function QuickApp:updateTariffData()
    -- Get current day energy rates.
    -- ENTSO-e service only returns 24 hour Rates on each request even if we define another "toDate" :(
    self:getServiceRateData(QuickApp.updateEnergyTariffTable, self, os.date("%Y%m%d0000"), os.date("%Y%m%d2300"), true)
    
    -- Get next 24 hour energy rates if they have been released, normally the next day energy rates are released after 12:00 UTC.
    -- We also need the next day rates to solve the midnight shift between 23:00 and 00:00.
    if (self.serviceSuccess and tonumber(os.date("%H", os.time())) >= self:getRateReleaseTime(self.timezoneOffset)) then
        fibaro.setTimeout(2000, function() 
                                    self:getServiceRateData(QuickApp.updateEnergyTariffTable, self, os.date("!%Y%m%d0000", os.time() + 86400), os.date("!%Y%m%d2300", os.time() + 86400), false) 
                                end)
    end
    
    self.serviceRequestTime = os.date(self:getDateFormat()) .." " ..os.date("%H:%M")
end

-- Variables and panel update display loop
function QuickApp:displayLoop(first)
    -- Set Update display loop to every full hour + 1 min
    local loopTime = 10000
    if not first then loopTime = (61 - tonumber(os.date("%M"))) * 60 * 1000 end

     -- Refresh variable values
    self:refreshVariables()

    -- Update FIBARO Tariff table if ON
    --if self.storeTariffInFibaro == true then self:updateFibaroTariffTable() end
    self:updateFibaroTariffTable()

    -- Start this display loop each hour
    fibaro.setTimeout(loopTime, function() self:displayLoop(false) end)
end
