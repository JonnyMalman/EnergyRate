# Energy Spot Price

The <b>ENTSO-e Energy Rate</b> QuickApp give you the current and coming energy spot price rates by hour from <a href="https://transparency.entsoe.eu/">ENTSO-e transparency platform</a> in your local currency. ENTSO-e is independent from any power company and no subscription or specific hardware is required to get this to work.
<i><h5>(*Local currency now reqires a free account at https://exchangerate.host)</h5></i>

:bulb: <i>If you pay your energy consumption by hour then this QA can save you money!</i>

This QA has spot prices for the following countries: <b>Austria, Belgium, Bosnia and Herz., Bulgaria, Croatia, Czech Republic, Denmark, Estonia, Finland, France, Germany, Greece, Hungary, Ireland, Italy, Latvia, Lithuania, Luxembourg, Netherlands, North Macedonia, Norway, Poland, Portugal, Romania, Serbia, Slovakia, Slovenia, Spain, Sweden, Switzerland, Ukraine </b>and<b> United Kingdom.</b>

<img src="img/README_img/readme1.png"/>
<img src="img/README_img/readme2.png"/>

<b><h1>How to install</h1></b>
After you have download, you need to unzip the file to get the <b>.fqa</b> file that can be install in FIBARO, I also provide the icon in <b>.png</b> format.

1. Click "+ Add device"
1. Choose Other Device
1. Choose Upload File
1. Select unzipped .fqa file

<b><h1>How it works</h1></b>

After you have add this QA in FIBARO devices, you need to set your local energy area that you belong to in the general variables <b>[EnergyArea]</b> to start collecting energy prices.

<img src="img/README_img/readme3.png"/>

The variation of energy hour level in <b>[EnergyHourLevel]</b> is calculated from price values you set in the QA local variables <b>[PriceLow], [PriceMedium], [PriceHigh], [PriceVeryHigh]</b>. You set those prices from what you feel is the correct level prices for you in your local currency* by consumed kWh.

<h4>(*If you use other than € Euro as your local currency, you need to get your own free "API access key". See "Exchange rate in local currency" below for more information.)</h4>

<br>

Global variables to use in scenes:
<b>[EnergyCurrentRate]</b> show current energy rate price in selected currency.
<b>[EnergyHourLevel]</b> show what price level it is current hour.
<b>[EnergyNextHourLevel]</b> show what price level it will be the next hour.
<b>[EnergyMonthLevel]</b> show what the avrage price is in current month.

To calculate different energy prices including tax, costs, grid, fee, etc, you change these values in the local QA variables.
<h4>(EnergyRate * ExchangeRate + OperatorCost * Losses * Adjustment + DealerCost + GridCost * Tax)</h4>

<img src="img/README_img/readme4.png"/>

--------------------------------------------------------------------------------------------------------------
- VeryLOW
- LOW
- MEDIUM
- HIGH
- VeryHIGH

Usage in Lua scen:
```lua
local value = hub.getGlobalVariable("EnergyHourLevel")
if (value == "VeryHIGH") then
...
end
```

Or in Block scen:

<img src="img/README_img/readme4.png"/>

The <b>ENTSO-e Energy Rate</b> QuickApp also store spot prices in the FIBARO Energy Tariff table.
You set how many days to store history in FIBARO tariff table in the QA variable <b>[TariffHistory]</b>.

<img src="img/README_img/readme5.png"/>

```lua
-- How to get FIBARO Energy Tariff data
local tariffData = api.get("/energy/billing/tariff")
local currentRate = tariffData.rate
local tariffTable = tariffData.additionalTariffs
...

-- How to get Global QA Tariff state data
local tariffTable = {}
local jsonString = fibaro.getGlobalVariable("EnergyStateTable")
-- Decode json string to Lua table
if (jsonString ~= nil and jsonString ~= "") then 
    tariffTable = json.decode(jsonString)
end
...

```
