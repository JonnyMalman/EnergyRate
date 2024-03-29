function QuickApp:createGlobalTableVariable()
    -- Create Energy state table global variable
    local table_var = {
            name=self.global_var_state_table_name,
            isEnum=false,
            readOnly=true,
            value=""
        }
    response, status = api.post('/globalVariables/', table_var)
    self:d("Create global variable: " ..tostring(table_var.name) .." => " ..tostring(status) .." - " ..tostring(response.message))
end

function QuickApp:createGlobalVariables()
    -- Create global variable Current energy rate price
    local rate_var = {
            name=self.global_var_current_rate_name,
            isEnum=false,
            readOnly=true,
            value=""
        }
    response, status = api.post('/globalVariables/', rate_var)
    self:d("Create global variable: " ..tostring(rate_var.name) .." => " ..tostring(status) .." - " ..tostring(response.message))

    -- Create Energy store in FIBARO Tariff global variable
    local tariff_var = {
            name=self.global_var_fibaro_tariff_name,
            isEnum=true,
            readOnly=true,
            value="ON",
            enumValues={"ON","OFF"}
        }
    response, status = api.post('/globalVariables/', tariff_var)
    self:d("Create global variable: " ..tostring(tariff_var.name) .." => " ..tostring(status) .." - " ..tostring(response.message))

    -- Create Energy Unit global variable
    local unit_var = {
            name=self.global_var_unit_name,
            isEnum=true,
            readOnly=true,
            value=self.default_unit,
            enumValues={"kWh","MWh"}
        }
    response, status = api.post('/globalVariables/', unit_var)
    self:d("Create global variable: " ..tostring(unit_var.name) .." => " ..tostring(status) .." - " ..tostring(response.message))

    -- Create Level rate global variable
    local level_var = {
            name=self.global_var_level_name,
            isEnum=true,
            readOnly=true,
            value="HIGH",
            enumValues={"Negative","VeryLOW","LOW","MEDIUM","HIGH","VeryHIGH"}
        }
    response, status = api.post('/globalVariables/', level_var)
    self:d("Create global variable: " ..tostring(level_var.name) .." => " ..tostring(status) .." - " ..tostring(response.message))

    -- Create Next Level rate global variable
    level_var.name = self.global_var_next_level_name
    response, status = api.post('/globalVariables/', level_var)
    self:d("Create global variable: " ..tostring(level_var.name) .." => " ..tostring(status) .." - " ..tostring(response.message))

    -- Create Month Level rate global variable
    level_var.name = self.global_var_month_level_name
    response, status = api.post('/globalVariables/', level_var)
    self:d("Create global variable: " ..tostring(level_var.name) .." => " ..tostring(status) .." - " ..tostring(response.message))
end

function QuickApp:setLocalVariables()
    -- Not required, but you can register and create your own account and get a token at ENTSO-e.
    -- Register an free ENTSO-e account at: https://transparency.entsoe.eu/
    -- How to get an Token: https://transparency.entsoe.eu/content/static_content/download?path=/Static%20content/API-Token-Management.pdf 
    self.token = self:getLocalVariable(self.variable_token_name, self.default_token)

    -- Exchange rate access key is required if use of other currency than Euro.
    -- Register a free Exchangerate.host account at: https://exchangerate.host and get your Access Key.
    self.exchangerate_Key = self:getLocalVariable(self.var_exchange_rate_Key_name, "")
    self.exchangeLastUpdate = self:getLocalVariable(self.var_exchange_last_update_name, "")
    self.exchangeRate = tonumber(self:getLocalVariable(self.var_exchange_rate_name, 0))
    
    -- Get/Set local rate price variables
    self.low_price = tonumber(self:getLocalVariable(self.variable_Low_name, self.default_Low_price))
    self.medium_price = tonumber(self:getLocalVariable(self.variable_Medium_name, self.default_Medium_price))
    self.high_price = tonumber(self:getLocalVariable(self.variable_High_name, self.default_High_price))
    self.veryhigh_price = tonumber(self:getLocalVariable(self.variable_VeryHigh_name, self.default_VeryHigh_price))

    self.addTariffDate = self:getLocalVariable(self.variable_add_date_tariff_name, "")

    -- Get/Set local variable price decimals
    self.decimals = self:getLocalVariable(self.variable_price_decimals_name, self.default_decimals)
    -- Get/Set local variable Days to keep FIBARO Tariff history
    self.tariffHistory = self:getLocalVariable(self.variable_tariff_history_name, self.default_tariff_history)
    -- Get/Set local variable tax
    self.tax = self:getLocalVariable(self.variable_tax_percentage_name, self.default_tax)
    
    -- Get/Set local variable operator cost
    self.operatorCost = self:getLocalVariable(self.variable_operator_cost_name, self.default_operator_cost)
    -- Get/Set local variable grid losses in percent
    self.gridLosses = self:getLocalVariable(self.variable_grid_losses_name, self.default_grid_losses)
    -- Get/Set local variable grid adjustment in percent
    self.gridAdjustment = self:getLocalVariable(self.variable_grid_adjustment_name, self.default_grid_adjustment)
    -- Get/Set local variable dealer cost
    self.dealerCost = self:getLocalVariable(self.variable_dealer_cost_name, self.default_dealer_cost)
    -- Get/Set local variable grid cost
    self.gridCost = self:getLocalVariable(self.variable_grid_cost_name, self.default_grid_cost)

    -- Get/Set local variable allow negative rates
    self.allowNegative = self:toBool(self:getLocalVariable(self.variable_allow_negative_name, self.default_allow_negative))

    -- Get/Set global FIBARO variables
    self.areaName = self:getGlobalFibaroVariable(self.global_var_area_name, self.default_area_name)
    self.areaCode = self:getAreaCode(self.areaName)
    self.unit = self:getGlobalFibaroVariable(self.global_var_unit_name, self.default_unit)

    self:refreshDisplayVariables()
end

function QuickApp:refreshDisplayVariables()
    -- Get FIBARO settings
    local fibaroSettings = api.get("/settings/info")
    self.currency = fibaroSettings.currency
    self.timezoneOffset = tonumber(fibaroSettings.timezoneOffset)
    self.dateFormat = fibaroSettings.dateFormat
    self.i18n = i18n:new(fibaroSettings.defaultLanguage)
        
    -- Refrech global variables
    self.areaName = fibaro.getGlobalVariable(self.global_var_area_name)
    self.areaCode = self:getAreaCode(self.areaName)
    self.unit = fibaro.getGlobalVariable(self.global_var_unit_name)
    if (self.unit == nil) then self.unit = "kWh" end

    -- Load Tariff data table
    self:loadEnergyTariffTable()

    -- Refresh QA variable values
    self.token = self:getVariable(self.var_token_name)
    self.tariffHistory = tonumber(self:getVariable(self.var_tariff_history_name))
    self.low_price = tonumber(self:getVariable(self.var_Low_name))
    self.high_price = tonumber(self:getVariable(self.var_High_name))
    self.veryhigh_price = tonumber(self:getVariable(self.var_VeryHigh_name))
    self.tax = tonumber(self:getVariable(self.var_tax_percentage_name))
    self.decimals = self:getVariable(self.var_price_decimals_name)
    self.valueFormat = self:getValueFormat()

    self.operatorCost = tonumber(self:getVariable(self.var_operator_cost_name))
    self.gridLosses = tonumber(self:getVariable(self.var_grid_losses_name))
    self.gridAdjustment = tonumber(self:getVariable(self.var_grid_adjustment_name))
    self.dealerCost = tonumber(self:getVariable(self.var_dealer_cost_name))
    self.gridCost = tonumber(self:getVariable(self.var_grid_cost_name))

    self.allowNegative = self:toBool(self:getVariable(self.var_allow_negative_name))

    self.addTariffDate = self:getVariable(self.var_add_date_tariff_name)

    -- Update QA Unit property
    self:updateProperty("unit", self:getCurrencySymbol() .. "/" ..tostring(self.unit))
    
    -- Set Energy rates data to display
    self:displayEnergyRate()
end

-- Get local QA variable, set to default value if variable is missing
function QuickApp:getLocalVariable(name, defaultValue)
    if defaultValue == nil then defaultValue = "" end
    if (name == nil) then return defaultValue end
    local value = self:getVariable(name)

    if (value == nil or value == "" or value == "nil") then
        self:setVariable(name, tostring(defaultValue))
        return defaultValue
    else
        return value
    end
end

-- Get local QA variable, set to default value if variable is missing
function QuickApp:getGlobalFibaroVariable(name, defaultValue)
    if defaultValue == nil then defaultValue = "" end
    if (name == nil) then return defaultValue end
    local value = fibaro.getGlobalVariable(name)

    if (value == nil or value == "" or value == "nil") then
        fibaro.setGlobalVariable(name, tostring(defaultValue))
        return defaultValue
    else
        return value
    end
end

-- Get default rate price based in local currency
function QuickApp:getDefaultPriceDecimals()
    if (self.currency == nil or self.currency == "") then
        local fibaroSettings = api.get("/settings/info")
        self.currency = fibaroSettings.currency
    end

    -- TODO: do an more accurat difference between currencies
    if (self.currency == "EUR" or self.currency == "USD" or self.currency == "GBP") then
        return "5"
    else
        return "3"
    end
end

-- Get default rate price based in local currency
function QuickApp:getDefaultRatePrice(percent)
    if (self.currency == nil or self.currency == "") then
        local fibaroSettings = api.get("/settings/info")
        self.currency = fibaroSettings.currency
    end

    -- TODO: do an more accurat difference between currencies
    if (self.currency == "EUR" or self.currency == "USD" or self.currency == "GBP") then
        return tostring(0.2 * (percent / 100))
    else
        return tostring(1 * (percent / 100))
    end
end
