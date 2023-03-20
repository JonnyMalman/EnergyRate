-- See "BZN" Area codes at: https://transparency.entsoe.eu/content/static_content/Static%20content/web%20api/Guide.html#_areas

function QuickApp:createAreaVariables()
    local level_var = {
            name=self.global_var_area_name,
            isEnum=true,
            readOnly=true,
            value=self.default_area_name,
            enumValues={"Austria (AT)","Belgium (BE)","Bosnia and Herz. (BA)","Bulgaria (BG)","Croatia (HR)","Czech Republic (CZ)","Denmark (DK1)","Denmark (DK2)","Estonia (EE)","Finland (FI)","France (FR)","Germany (DE-LU)","Greece (GR)","Hungary (HU)","Ireland (SEM)","Italy (Calabria)","Italy (SACOAC)","Italy (SACODC)","Italy (Centre-North)","Italy (Centre-South)","Italy (North)","Italy (Sardinia)","Italy (Sicily)","Italy (South)","Latvia (LV)","Lithuania (LT)","Luxembourg (LU)","Netherlands (NL)","North Macedonia (MK)","Norway (NO1)","Norway (NO2)","Norway (NO2NSL)","Norway (NO3)","Norway (NO4)","Norway (NO5)","Poland (PL)","Portugal (PT)","Romania (RO)","Serbia (RS)","Slovakia (SK)","Slovenia (SI)","Spain (ES)","Sweden (SE1)","Sweden (SE2)","Sweden (SE3)","Sweden (SE4)","Switzerland (CH)","Ukraine (UA-IPS)","United Kingdom (GB)"}
    }
    api.post('/globalVariables/',level_var)    
end

function QuickApp:getAreaCode(areaName)
    -- Set default Area code if "areaName" is missing.
    if areaName == nil or areaName == "" then areaName = self.default_area_name end
    
    if (areaName == "Austria (AT)") then return "10YAT-APG------L" end
    if (areaName == "Belgium (BE)") then return "10YBE----------2" end
    if (areaName == "Bosnia and Herz. (BA)") then return "10YBA-JPCC-----D" end
    if (areaName == "Bulgaria (BG)") then return "10YCA-BULGARIA-R" end
    if (areaName == "Croatia (HR)") then return "10YHR-HEP------M" end
    if (areaName == "Czech Republic (CZ)") then return "10YCZ-CEPS-----N" end
    if (areaName == "Denmark (DK1)") then return "10YDK-1--------W" end
    if (areaName == "Denmark (DK2)") then return "10YDK-2--------M" end
    if (areaName == "Estonia (EE)") then return "10Y1001A1001A39I" end
    if (areaName == "Finland (FI)") then return "10YFI-1--------U" end
    if (areaName == "France (FR)") then return "10YFR-RTE------C" end
    if (areaName == "Germany (DE-LU)") then return "10Y1001A1001A82H" end
    if (areaName == "Greece (GR)") then return "10YGR-HTSO-----Y" end
    if (areaName == "Hungary (HU)") then return "10YHU-MAVIR----U" end
    if (areaName == "Ireland (SEM)") then return "10Y1001A1001A59C" end
    if (areaName == "Italy (Calabria)") then return "10Y1001C--00096J" end
    if (areaName == "Italy (Centre-North)") then return "10Y1001A1001A70O" end
    if (areaName == "Italy (Centre-South)") then return "10Y1001A1001A71M" end
    if (areaName == "Italy (North)") then return "10Y1001A1001A73I" end
    if (areaName == "Italy (SACOAC)") then return "10Y1001A1001A885" end
    if (areaName == "Italy (SACODC)") then return "10Y1001A1001A893" end
    if (areaName == "Italy (Sardinia)") then return "10Y1001A1001A74G" end
    if (areaName == "Italy (Sicily)") then return "10Y1001A1001A75E" end
    if (areaName == "Italy (South)") then return "10Y1001A1001A788" end
    if (areaName == "Latvia (LV)") then return "10YLV-1001A00074" end
    if (areaName == "Lithuania (LT)") then return "10YLT-1001A0008Q" end
    if (areaName == "Luxembourg (LU)") then return "10Y1001A1001A82H" end
    if (areaName == "Netherlands (NL)") then return "10YNL----------L" end
    if (areaName == "North Macedonia (MK)") then return "10YMK-MEPSO----8" end
    if (areaName == "Norway (NO1)") then return "10YNO-1--------2" end
    if (areaName == "Norway (NO2)") then return "10YNO-2--------T" end
    if (areaName == "Norway (NO2NSL)") then return "50Y0JVU59B4JWQCU" end
    if (areaName == "Norway (NO3)") then return "10YNO-3--------J" end
    if (areaName == "Norway (NO4)") then return "10YNO-4--------9" end
    if (areaName == "Norway (NO5)") then return "10Y1001A1001A48H" end
    if (areaName == "Poland (PL)") then return "10YPL-AREA-----S" end
    if (areaName == "Portugal (PT)") then return "10YPT-REN------W" end
    if (areaName == "Romania (RO)") then return "10YRO-TEL------P" end
    if (areaName == "Serbia (RS)") then return "10YCS-SERBIATSOV" end
    if (areaName == "Slovakia (SK)") then return "10YSK-SEPS-----K" end
    if (areaName == "Slovenia (SI)") then return "10YSI-ELES-----O" end
    if (areaName == "Spain (ES)") then return "10YES-REE------0" end
    if (areaName == "Sweden (SE1)") then return "10Y1001A1001A44P" end
    if (areaName == "Sweden (SE2)") then return "10Y1001A1001A45N" end
    if (areaName == "Sweden (SE3)") then return "10Y1001A1001A46L" end
    if (areaName == "Sweden (SE4)") then return "10Y1001A1001A47J" end
    if (areaName == "Switzerland (CH)") then return "10YCH-SWISSGRIDZ" end
    if (areaName == "Ukraine (UA-IPS)") then return "10Y1001C--000182" end
    if (areaName == "United Kingdom (GB)") then return "10YGB----------A" end

    return "" -- No match
end
