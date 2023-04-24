function QuickApp:createGlobalVariables()   
    -- Create Unit global variable
    local unit_var = {
            name=self.global_var_unit_name,
            isEnum=true,
            readOnly=true,
            value="kWh",
            enumValues={"kWh","MWh"}
        }
    api.post('/globalVariables/',unit_var)

    -- Create Level rate global variable
    local level_var = {
            name=self.global_var_level_name,
            isEnum=true,
            readOnly=true,
            value="HIGH",
            enumValues={"VeryLOW","LOW","MEDIUM","HIGH","VeryHIGH"}
        }
    api.post('/globalVariables/',level_var)

    -- Create Next Level rate global variable
    level_var.name = self.global_var_next_level_name
    api.post('/globalVariables/',level_var)

    -- Create Month Level rate global variable
    level_var.name = self.global_var_month_level_name
    api.post('/globalVariables/',level_var)
end

function QuickApp:setDefaultVariables()
    -- Not required, but you can register and create your own account and get a token at ENTSO-e.
    -- Register an free ENTSO-e account at: https://transparency.entsoe.eu/
    -- How to get an Token: https://transparency.entsoe.eu/content/static_content/download?path=/Static%20content/API-Token-Management.pdf 
    if self.token == nil or self.token == "" then      
        self.token = self.default_entsoe_token
        self:setVariable(self.variable_token_name, self.token)
    end

    -- Set local rate price variables
    if self.low_price == nil or self.low_price == "" then 
        self.low_price = self.default_Low_price
        self:setVariable(self.variable_Low_name, self.low_price) 
    end
    if self.medium_price == nil or self.medium_price == "" then 
        self.medium_price = self.default_Medium_price
        self:setVariable(self.variable_Medium_name, self.medium_price) 
    end
    if self.high_price == nil or self.high_price == "" then 
        self.high_price = self.default_High_price
        self:setVariable(self.variable_High_name, self.high_price) 
    end
    if self.veryhigh_price == nil or self.veryhigh_price == "" then 
        self.veryhigh_price = self.default_VeryHigh_price
        self:setVariable(self.variable_VeryHigh_name, self.veryhigh_price) 
    end

    -- Set local variable tax
    if self.tax == nil or self.tax == "" then
        self.tax = self.default_tax_percentage
        self:setVariable(self.variable_tax_percentage_name, self.tax)
    end
    
     -- Set local variable operator
    if self.operator == nil or self.operator == "" then
        self.operator = self.default_operator_cost
        self:setVariable(self.variable_operator_cost_name, self.operator)
    end

-- Set local variable losses
    if self.losses == nil or self.losses == "" then
        self.losses = self.default_grid_losses
        self:setVariable(self.variable_grid_losses_name, self.losses)
    end

-- Set local variable adjustment
    if self.adjustment == nil or self.adjustment == "" then
        self.adjustment = self.default_adjustment
        self:setVariable(self.variable_adjustment_name, self.adjustment)
    end

-- Set local variable dealer
    if self.dealer == nil or self.dealer == "" then
        self.dealer = self.default_dealer_cost
        self:setVariable(self.variable_dealer_cost_name, self.dealer)
    end

-- Set local variable grid
    if self.grid == nil or self.grid == "" then
        self.grid = self.default_grid_cost
        self:setVariable(self.variable_grid_cost_name, self.grid)
    end
    
    -- Set local variable Days to keep FIBARO Tariff history
    if self.tariffHistory == nil or self.tariffHistory == "" then
        self.tariffHistory = self.default_tariff_history
        self:setVariable(self.variable_tariff_history_name, self.tariffHistory)
    end

    -- Set global variable Energy ENTSO-e Area name
    if self.areaName == nil or self.areaName == "" then
        self.areaName = self.default_area_name
    end
    if self.areaCode == nil or self.areaCode == "" then
        fibaro.setGlobalVariable(self.global_var_area_name, self.areaName)
    end

    self:refreshVariables()
end

function QuickApp:refreshVariables()
    -- Get FIBARO settings
    local fibaroSettings = api.get("/settings/info")
    self.currency = fibaroSettings.currency
    self.timezoneOffset = tonumber(fibaroSettings.timezoneOffset)
    --self.dateFormat = tonumber(fibaroSettings.dateFormat)
    --self.timeFormat = tonumber(fibaroSettings.timeFormat)
    --self.decimalMark = tonumber(fibaroSettings.decimalMark)
    self.i18n = i18n:new(fibaroSettings.defaultLanguage)
        
    -- Refresh variable values
    self.token = self:getVariable(self.variable_token_name)
    self.tariffHistory = tonumber(self:getVariable(self.variable_tariff_history_name))
    self.low_price = tonumber(self:getVariable(self.variable_Low_name))
    self.medium_price = tonumber(self:getVariable(self.variable_Medium_name))
    self.high_price = tonumber(self:getVariable(self.variable_High_name))
    self.veryhigh_price = tonumber(self:getVariable(self.variable_VeryHigh_name))
    self.areaCode = self:getAreaCode(self.areaName)
    self.tax = tonumber(self:getVariable(self.variable_tax_percentage_name))
    self.operator = tonumber(self:getVariable(self.variable_operator_cost_name))
    self.losses = tonumber(self:getVariable(self.variable_grid_losses_name))
    self.adjustment = tonumber(self:getVariable(self.variable_adjustment_name))
    self.dealer = tonumber(self:getVariable(self.variable_dealer_cost_name))
    self.grid = tonumber(self:getVariable(self.variable_grid_cost_name))
    self.areaName = fibaro.getGlobalVariable(self.global_var_area_name)
    self.unit = fibaro.getGlobalVariable(self.global_var_unit_name)

    self:updateProperty("unit", self.currency .. "/" ..tostring(self.unit))
end
