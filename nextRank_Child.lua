class 'ENTSOE_Next_Rank' (QuickAppChild)
function ENTSOE_Next_Rank:__init(device)
    -- You should not insert code before QuickAppChild.__init.
    QuickAppChild.__init(self, device) -- We must call a constructor from the parent class
end

function ENTSOE_Next_Rank:setValue(value)
    self:updateProperty("value", value)
end

function ENTSOE_Next_Rank:setUnit(unit)
    self:updateProperty("unit", unit)
end

function ENTSOE_Next_Rank:setLog(log)
    self:updateProperty("log", log)
end


-- Validate if child panel exists, if not create it
function QuickApp:validateChildren()
    self:d("Validate QuickApp Child")
    for id, device in pairs(self.childDevices) do
        self:d(tostring(id) .." = " ..device.name)

        if (device.name == self.child_rank_name) then
            self.next_rank_device_id = id
            self:d(tostring(id) .." - child_rank_name: " ..device.name)
        end
    end

    if self.next_rank_device_id == nil then
        self:d("Create QuickApp Child")
        self:createRankChild()
    end
end

-- Create child panel
function QuickApp:createRankChild()
    local child = self:createChildDevice({
        name = self.child_rank_name,
        type = "com.fibaro.multilevelSensor",
    }, ENTSOE_Next_Rank)
    self.next_rank_device_id = child.id
end