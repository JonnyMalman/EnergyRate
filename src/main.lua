--[[
    =======================================================================================================    
        MIT License

        Copyright © 2023 JAM Data® AB by Jonny Mälman

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.    
    =======================================================================================================    

    ENTSO-e Energy Rate is an FIBARO QuickApp that get current Spot prices for almost every european countries and is independent from any energy power company for free.

    How to get your own ENTSO-e Token:
    I´ve provide an Token that works "out of the box", but can be changed in the future, so if you like you can create your own free token at ENTSO-e, but not required.
    Register an ENTSO-e account at: https://transparency.entsoe.eu/
    How to get an Token: https://transparency.entsoe.eu/content/static_content/download?path=/Static%20content/API-Token-Management.pdf

    The Exchange rate service (https://exchangerate.host) that is used in this QuickApp gets your local currency for free up to 1000 request/month if you register a account.
    If you use other currency than EUR, you need create and add the API Access Key from https://exchangerate.host in the local variables [ExchAccessKey].

    This is the first time I have developed in Lua language, so have some indulgence, but hey it works and I hope it works for U2 ;)
    I would appreciate if you have any feedback or suggestions to make this QuickApp better or more usefull, please send me an email at energyrate@jamdata.com and I´ll try to do my best :)

    And please give this QA your rating ⭐⭐⭐⭐⭐ in FIBARO Marketplace if you like it or not, I'll would be very happy!

    CHANGELOG:
    v1.0 First release 2023-01
    
    v1.1 New feature release 2023-03
        - Keeps Tariff rate history in FIBARO.
        - Show more usefull info in QA panel.
        - Add new general month average level variable "EnergyMonthLevel" for those that pay energy consumtion per month average.
        - Add new QA variable "TariffHistory" for how many days to store history in FIBARO tariff rates.
        - Localized panel text for language: EN, DK, NO, SV (if you want to help me with translation, please send me an email at energyrate@jamdata.com)

        Braking changes that you need to change in your scenes if your using first release v1.0:
            General variable name change from "EnergyRateArea" to "EnergyArea".
            General variable name change from "EnergyRateMedium" to "EnergyMediumPrice".
            General variable name change from "EnergyRateLevel" to "EnergyHourLevel".
            General variable name change from "EnergyRateNextLevel" to "EnergyNextHourLevel".

    v1.2 Customer wishes release 2023-04
        - Option to add tax to the energy price.
        - Show if service error message in display panel.

    v1.3 Customer improvements 2023-05
        - Rewrite energy tariff table to store in general variable instead of FIBARO tariff table to solve negative energy prices.
        - Fix UTC time when request next day energy prices from ENTSO-e.
        - Improved energy value display formatting, with price decimal local QA variable, also show correct price if very low or negative price. (Except FIBARO tariff that can't show negative values)
        - All the rate levels are moved from general to local QA variables and are in real local energy price.
        - Move general variable "EnergyTaxPercentage" to local QA variable as "EnergyTax".
        - Add new general variable ON/OFF to store prices in FIBARO Tariff rate table.
        - Add translation in Portuguese (Thanks to Leandro C.).
        - Add local QA cost variables to calculate energy prices: {((ENTSO_price + operatorCost) x losses x adjustment) + dealer + localgrid} x tax (by Leandro C.).

    v1.4 Bug fix release 2023-05
        - Fix Update timer for display panel and variables. 

    v1.5 Fix Exchange rate 2023-06
        - Fix historical exchange rates when show in FIBARO Tariff table.
        - Add QA varible [AddTariffDate] if you want to add historical rates to energy table. Input format: "YYYY-MM-DD".

        Braking changes from v1.4:
            All new tariff rates will now be stored in a new general variable [EnergyTariffTable] and all you old data will remain in [EnergyStateTable] until you delete it.

    v1.6 Fix QA Child value display 2023-08
        - Corrected QA Child to show negative values.
        - Add local QA variable [NegativeRates] to allow negative rates ON/OFF
        - Add new rate level if negative rate 🟣
        - Add general variable [EnergyCurrentRate] to easier read current energy rate price from other QA or scenes.

    v1.7 Fix Exchange rate API 2023-10
        - Update to support the new Exchangerate.Host API.
          This release Requires API Access Key from https://exchangerate.host only if you use other currency than Euro €.
          (NOTE! Historical exchange rates can't be fetch with this release because of changes at Exchangerate.Host)

    v1.7.1 Display panel fix 2023-10
        - Display panel information fix.
    
]]

-- QuickApp Initialize
function QuickApp:onInit()
    self.debugLog = false   -- Write to debug console true/false. Is set by local variable [ConsoleDebug]=ON/OFF.
    self.deviceName = "ENTSO-e Energy Rate"
    self.version = "1.7.1"
    self.Copyright = "Copyright © 2023 JAM Data® AB"

    self.httpClient = net.HTTPClient()
    
    -- Variables for exchangerate.host Api service if use of other currency than Euro €.
    -- https://exchangerate.host  -- Free account now only support for non secure http and max 1000 requests/month. No history exchange rate can requests on a free account!
    self.exchangerate_baseURL = "http://api.exchangerate.host/"
    
    -- Variables for ENTSO-e Transparency Platform Api service
    -- https://transparency.entsoe.eu/content/static_content/Static%20content/web%20api/Guide.html
    self.entsoe_baseURL = "https://web-api.tp.entsoe.eu/api"
    self.child_rank_name = "ENTSO-e Next Energy Rate"             -- Name of next energy price QA child
    self.next_rank_device_id = nil                                -- Id of next energy price QA child

    -- NOTE! Local QA variable names can only have maximun of 15 charachters.
    self.var_debug_log_name = "ConsoleDebug"                      -- Variable name of Debug log to console On/Off.
    self.var_token_name = "ENTSOE_Token"                          -- Variable name of ENTSO-e Token key.
    self.var_tariff_history_name = "TariffHistory"                -- Variable name of tariff day(s) history.
    self.var_Low_name = "PriceLow"                                -- Variable name of low price.
    self.var_Medium_name = "PriceMedium"                          -- Variable name of medium price.
    self.var_High_name = "PriceHigh"                              -- Variable name of high price.
    self.var_VeryHigh_name = "PriceVeryHigh"                      -- Variable name of very high price.
    self.var_tax_percentage_name = "EnergyTax"                    -- Variable name of energy tax.
    self.var_price_decimals_name = "PriceDecimals"                -- Variable name of number of decimals when display energy prices.
    self.var_add_date_tariff_name = "AddTariffDate"               -- Variable name of date to add historical tariff rate.
    self.var_operator_cost_name = "OperatorCost"                  -- Variable name of Grid Operator deviation costs (€/kWh or €/MWh)
    self.var_grid_losses_name = "GridLossesPct"                   -- Variable name of Grid Losses percent cost (%).
    self.var_grid_adjustment_name = "AdjustmentPct"               -- Variable name of Grid Adjustment percent cost added to the Grid Losses (%).
    self.var_dealer_cost_name = "DealerFee"                       -- Variable name of Dealer fee cost (€/kWh or €/MWh).
    self.var_grid_cost_name = "LocalGridCost"                     -- Variable name of Local Grid cost (€/kWh or €/MWh).
    self.var_allow_negative_name = "NegativeRates"                -- Variable name of Allow negative rates ON/OFF.
    self.var_exchange_last_update_name = "ExchLastUpdate"         -- Variable name of Laste date exchange rate update.
    self.var_exchange_rate_name = "ExchangeRate"                  -- Variable name of current exchange rate.
    self.var_exchange_rate_Key_name = "ExchAccessKey"             -- Variable name of Exchangerate.host API Access Key (Required only if your currency is other than € Euro).

    -- Global variable names
    self.global_var_unit_name = "EnergyUnit"                      -- Global variable name of energy unit (KWh or MWh).
    self.global_var_state_table_name = "EnergyTariffTable"        -- Global variable name of energy tariff table.
    self.global_var_area_name = "EnergyArea"                      -- Global variable name of energy area.
    self.global_var_level_name = "EnergyHourLevel"                -- Global variable name of energy level.
    self.global_var_next_level_name = "EnergyNextHourLevel"       -- Global variable name of energy level.
    self.global_var_month_level_name = "EnergyMonthLevel"         -- Global variable name of energy level.
    self.global_var_fibaro_tariff_name = "EnergyTariffInFibaro"   -- Global variable name of show Tariff rates i FIBARO On/Off.
    self.global_var_current_rate_name = "EnergyCurrentRate"       -- Global variable name of current energy rate price.
            
    -- Default values to set if missing
    self.default_token = "f442d0b3-450b-46d7-b752-d8d692fdb2c8"   -- See "How to get your own Token:" above.
    self.default_area_name = "[SELECT AREA]"                      -- Need to select an area before request ENTSO-e.
    self.default_unit = "kWh"                                     -- Show kWh or MWh in display panel (FIBARO Tariff table is always in kWh)
    self.default_tax = "0"                                        -- Default 0% energy tax.
    self.default_tariff_history = "62"                            -- Default 62 days ~2 month. (FIBARO Tariff panel will be slow to open if it's too many days)

    self.default_decimals = self:getDefaultPriceDecimals()        -- Get default number of decimals based on currency for price display.
    self.default_Low_price = self:getDefaultRatePrice(10)         -- Set 10% of medium price based on local currency.
    self.default_Medium_price = self:getDefaultRatePrice(100)     -- Set 100% of medium price based on local currency.
    self.default_High_price = self:getDefaultRatePrice(160)       -- Set 160% of medium price based on local currency.
    self.default_VeryHigh_price = self:getDefaultRatePrice(250)   -- Set 250% of medium price based on local currency.
    
    self.default_operator_cost = "0"                              -- Default Grid Operator costs (0 €/kWh or 0 €/MWh).
    self.default_grid_losses = "0"                                -- Default Grid Losses in percent (0 %).
    self.default_grid_adjustment = "0"                            -- Default adjustment added to the Grid Losses in percent (0 %).
    self.default_dealer_cost = "0"                                -- Default Dealer cost (0 €/KWh or 0 €/MWh).
    self.default_grid_cost = "0"                                  -- Default Local Grid cost (0 €/KWh or 0 €/MWh).
    self.default_allow_negative = "ON"                            -- Default Allow negative rates.

    -- Fixed QA variables
    self.nextday_releaseHourUtc = 12                              -- The UTC hour of the day when ENTSO-e releses the next day prices.
    self.dateFormat = self:getDateFormat()                        -- The FIBARO Date format setting ("YY-MM-DD", "DD.MM.YY" or "MM/DD/YY").
    self.valueFormat = self:getValueFormat(self.default_decimals) -- The value formatting of decimals when display Energy prices ie. "%.3f"
    self.serviceRequestTime = "--"                                -- Last datetime when we request ENTSO-e webservice.
    self.serviceSuccess = true                                   -- Request ENTSO-e service success or fault.
    self.exchangeRateUpdated = false                              -- Status if Exchange Rate is updated or not.
    self.exchangeLastDate = ""                                    -- Last datetime when we request Exchange Rate Api service.
    self.exchangeRate = 0                                         -- Set default excahnge rate 0.
    self.entsoeServiceMessage = ""                                -- Request ENTSO-e service error message.
    self.exchServiceMessage = ""                                  -- Request Exchange rate service error message.
    self.lastVariableUpdate = "--"                                -- Last general variable update.
    self.addTariffDate = ""                                       -- Add historical tariff rates for a date (YYYY-MM-DD).
    self.dataChanged = true                                       -- If data has change then display panel need to be updated.

    -- Let´s start the engine
    self:mainStart()
end

-- QA Main start execution
function QuickApp:mainStart()
    self.debugLog = self:toBool(self:getLocalVariable(self.var_debug_log_name, "OFF"))
    self:debug(">>>> Start QuickApp " ..self.deviceName .." v" ..self.version .." - " ..self.Copyright .." <<<<")
    
    -- Create global varaiables (See: defaults)
    self:createAreaVariables()    
    self:createGlobalVariables()

    -- Init Child device to display next hour rate in FIBARO (See: QAChild_NextRank)
    self:initChildDevices({["com.fibaro.multilevelSensor"] = ENTSOE_Next_Rank})
    self:validateChildren()
    
    -- set default values (See: defaults)
    self:setLocalVariables()           

    -- Start main loop of requesting ExchangeRate and ENTSO-e services
    self:mainLoop(true)
end

-- Main loop that executes each minute
function QuickApp:mainLoop(init)
    local loopTime = 2000
       
    -- Get current Exchange rate from Exchangerate.host Api Service if local currency is other than € Euro
    local dataChanged = self:getServiceExchangeRate(init)

    if (init == false) then
        -- Update Energy Rates table from ENSO-e Service if AreaCode is set
        if (self.areaCode ~= "") then self:refreshEnergyTariffTable() end
        
        -- Update variable and display panel if next hour
        if (not self:isDisplayPanelUpToDate(dataChanged)) then        
            fibaro.setTimeout(2000, function()
                self:refreshDisplayVariables() -- Update Variables and Display panel
                self:updateFibaroTariffTable() -- Update FIBARO Tariff table if ON
            end)
        end

        -- Set to loop to each minute
        loopTime = 60000 - (os.date("%S") * 1000)
    end

    -- Start this main loop each minute
    fibaro.setTimeout(loopTime, function() self:mainLoop(false) end)
end

-- Trigger if panel "Refresh" button pressed
function QuickApp:refresh_action()
    self:d("Execute ENTSO-e service update on button event...")
    self:updateView("refreshButton", "text", "⌛ " ..self.i18n:get("Refreshing") .."...")
    
    -- Update Tariff table, variables and panel
    self.dataChanged = true
    self:getServiceExchangeRate(true)
    self:refreshEnergyTariffTable()
    fibaro.setTimeout(5000, function() self:refreshDisplayVariables() end)    
end
