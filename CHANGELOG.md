# Changelog

## [v1.0] - 2023-01
- First release

## [v1.1] - 2023-03
- Keeps Tariff rate history in FIBARO.
- Show more usefull info in QA panel.
- Added new global month level variable "EnergyMonthLevel" for those that pay energy consumption per month avrage.
- Added new QA variable "TariffHistory" for how many days to store history in FIBARO tariff rates.
- Localized panel text for language: EN, DK, NO, SV.

<br></br>
<i><b>Breaking changes that you need to update in your scenes and delete the old variables if you using first release v1.0:</b></i>
- Global variable name change: "<b>EnergyRateArea</b>" to "<b>EnergyArea</b>".
- Global variable name change: "<b>EnergyRateMedium</b>" to "<b>EnergyMediumPrice</b>".
- Global variable name change: "<b>EnergyRateLevel</b>" to "<b>EnergyHourLevel</b>".
- Global variable name change: "<b>EnergyRateNextLevel</b>" to "<b>EnergyNextHourLevel</b>".

## [v1.2] - 2023-04
- Add global variable for energy tax.

## [v1.3] - Customer improvements 2023-05
- Rewrite energy tariff table to store in general variable instead of FIBARO tariff table to solve negative energy prices.
- Fix UTC time when request next day energy prices from ENTSO-e.
- Improved energy value display formatting, with price decimal local QA variable, also show correct price if very low or negative price. (Except FIBARO tariff that can't show negative values)
- All the rate levels are moved from general to local QA variables and are in real local energy price.
- Move general variable "EnergyTaxPercentage" to local QA variable as "EnergyTax".
- Add new general variable ON/OFF to store prices in FIBARO Tariff rate table.
- Add translation in Portuguese (Thanks to Leandro C.).
- Add local QA cost variables to calculate energy prices: {((ENTSO_price + operatorCost) x losses x adjustment) + dealer + localgrid} x tax (by Leandro C.).

## [v1.4] - bug fix release 2023-05
- Fix Update timer for display panel and variables. 

## [v1.5] - fix Exchange rate 2023-06
- Fix historical exchange rates when show in FIBARO Tariff table.
- Add QA varible [AddTariffDate] if you want to add historical rates to energy table. Input format: "YYYY-MM-DD".

<i><b>Braking changes from v1.4:</b></i>
    All new tariff rates will now be stored in a new general variable [EnergyTariffTable] and all you old data will remain in [EnergyStateTable] until you delete it.

## [v1.6] - Fix QA Child value display 2023-07
- Corrected QA Child to show negative values.
- Add Check for new QA update button. (Beta)
