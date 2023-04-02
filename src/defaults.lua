function QuickApp:createGlobalVariables()
    -- Create medium rate price global variable
    local medium_var = {
            name=self.global_var_medium_price_name,
            isEnum=false,
            readOnly=false,
            value="0.2", -- 0,2 EUR/kWh
            enumValues=nil
        }
    api.post('/globalVariables/',medium_var)
    
    -- Create tax percentage global variable
    local tax_var = {
            name=self.global_var_tax_percentage_name,
            isEnum=false,
            readOnly=false,
            value="0", -- 0 %
            enumValues=nil
        }
    api.post('/globalVariables/',tax_var)

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

    -- Set local variable Days to keep FIBARO Tariff history
    if self.tariffHistory == nil or self.tariffHistory == "" then
        self.tariffHistory = self.default_tariff_history
        self:setVariable(self.variable_tariff_history_name, self.tariffHistory)
    end

    -- Set local variable medium price rate
    if self.mediumPrice == nil or self.mediumPrice == "" then
        self.mediumPrice = self.default_medium_price
        self:setGlobalVariable(self.global_var_medium_price_name, self.mediumPrice)
    end

    -- Set local variable tax
    if self.tax == nil or self.tax == "" then
        self.tax = self.default_tax_percentage
        self:setGlobalVariable(self.global_var_tax_percentage_name, self.tax)
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
    self.tariffHistory = self:getVariable(self.variable_tariff_history_name)
    self.mediumPrice = fibaro.getGlobalVariable(self.global_var_medium_price_name)
    self.tax = fibaro.getGlobalVariable(self.global_var_tax_percentage_name) / 100
    self.areaName = fibaro.getGlobalVariable(self.global_var_area_name)
    self.areaCode = self:getAreaCode(self.areaName)
    self:updateProperty("unit", self.currency .. "/kWh")
end
