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

