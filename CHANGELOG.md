# Changelog

## [v1.8] - 2024-01

- Next day energy rates in FIBARO Tariff table was not calculated with exchange rate if use of other currency than Euro €.
- Add general variable <b>[EnergyNextRate]</b> to easier read next hour energy rate price from other QA or scene.

## [V1.7.2] - 2023-10

- Minor display panel fix.
- Variable correction on Low, Medium, High and very High price.

## [V1.7] - 2023-10

- Update to get local currency from changed API at Exchangerate.Host.
This release only requires a "API Access Key" from https://exchangerate.host if you use other currency than Euro €.
<i>(NOTE! Add historical tariff rates with [AddTariffDate] variable that was introduced in v1.5 now only works with current exchange! This is because of the new restrictions at Exchangerate.Host on a free account)</i>
- The new function to "Check for new QA version" that was introduced in v1.6 is removed. FIBARO OS is not stable enough to request a website, the QA crash to often for a usefull feature.
- Fix icon images to show correct direction on negative values.

## [V1.6] - 2023-08

- Corrected QA Child to show negative values.
- Add general variable [<b>EnergyCurrentRate</b>] to easier get current energy rate in scenes or other QA's.
- Add Check for new QA update button.

## [V1.5] - 2023-06

- Fix historical exchange rates when display in FIBARO Tariff table.
- Add QA varible [<b>AddTariffDate</b>] if you want to add historical rates to the energy rate table. Input format: "<b>YYYY-MM-DD</b>".

<b><i>Braking changes from v1.4:</i></b>
- All new tariff rates will now be stored in a new general variable [<b>EnergyTariffTable</b>] and all old data will remain in [<b>EnergyStateTable</b>] until you delete it.

## [V1.4] - 2023-05

- Fix timer update for QA display panel and general variables.

## [V1.3] - 2023-05

- Rewrite energy tariff table to store in general variable instead of FIBARO tariff table to solve negative energy prices.
- Fix UTC time when request next day energy prices from ENTSO-e.
- Improved energy value formatting in panel display with price decimal local variable that shows correct price if negative price.
- All the rate levels are moved from general to local variables and are in acctual energy price in local currency.
- Move general variable "EnergyTaxPercentage" to local variable as "EnergyTax".
- Add general variable ON/OFF to store prices in FIBARO Tariff rate table.
- Add translation in Portuguese PT (Thanks to Leandro C.).
- Add more cost variables to calculate energy prices: {((ENTSO_price + operatorCost) x losses x adjustment) + dealer + localgrid} x tax (by Leandro C.).

## [V1.2] - 2023-04

- Option to set tax to the energy prices in procentage.
- Display more info on ENTSO-e service error.

## [V1.1] - 2023-03

- Keeps Tariff rate history in FIBARO tariff table.
- Show more usefull info in QA panel.
- Added new general month level variable "<b>EnergyMonthLevel</b>" for those that pay energy consumption per month avrage.
- Added new QA variable "<b>TariffHistory</b>" for how many days to store history in FIBARO tariff rates.
- Localized panel text for language: EN, DK, NO, SV

<b><i>Breaking changes that you need to update in your scenes and delete the old variables if you using first release v1.0:</i></b>
- General variable name change: "<b>EnergyRateArea</b>" to "<b>EnergyArea</b>".
- General variable name change: "<b>EnergyRateMedium</b>" to "<b>EnergyMediumPrice</b>".
- General variable name change: "<b>EnergyRateLevel</b>" to "<b>EnergyHourLevel</b>".
- General variable name change: "<b>EnergyRateNextLevel</b>" to "<b>EnergyNextHourLevel</b>".

## [V1.0] - 2023-01

- First release
