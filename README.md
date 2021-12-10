# soschuva_hail
R and Python scripts to read and process weather radar, lightning and other data related to hailstorm cases in SOS-CHUVA Project. Part of dissertation ["Microphysics, Kinematics and Electrification in Hail Producing Tropical Storms during SOS-CHUVA Project"](https://teses.usp.br/teses/disponiveis/14/14133/tde-06052019-155657/en.php) @ IAG/USP - Brazil.

***Disclaimer**: I'm still improving these scripts (specially converting from old Jupyter notebooks to sets of python scripts)*

More info about each folder can be found in each respective README.

- ## [ForTraCC_Processing](ForTraCC_Processing/README.md)
Processing ForTraCC-Radar clusters and families per case as lists using `tidyverse` functions.

- ## [General_Processing](General_Processing/README.md)

## Hailpads_Processing [R]
Processing hailpads data per case as lists using `tidyverse` functions.

## Lightning_Processing [R]
Processing BrasilDAT lightning data with `tidyverse` functions, converting strokes to flashes using [`DBSCAN`](https://github.com/mhahsler/dbscan) package.

- ## [MultiDoppler_Processing](MultiDoppler_Processing/README.md)

## PyART_CSURT_Tutorial [Python]
A small tutorial about working with brazilian weather radar data in Python with the following packages:

- [`Py-ART`](https://github.com/ARM-DOE/pyart)
- [`CSU_RadarTools`](https://github.com/CSU-Radarmet/CSU_RadarTools)

## Radar_Processing [Python, R]
Processing weather radar data in two fronts:
- In Python:
  - Calculate hydrometeor classification (using [`CSU_RadarTools`](https://github.com/CSU-Radarmet/CSU_RadarTools)) and plot with polarimetric variables
  - Plot PPIs of single-pol variables
- In R:
  - Read and view CAPPI data (specially from São Roque radar)

## Reanalysis_Processing [Python]
Processing ERA5 reanalysis data using:

- [`xarray`](http://xarray.pydata.org/en/stable/)
- [`MetPy`](https://unidata.github.io/MetPy/latest/index.html)

## Satellite_Processing [Python]
Processing GOES-16 data with the following installed packages:

- `netcdf4` (conda-forge)
- `basemap` (conda-forge)
- `basemap-data-hires` (conda-forge)
- `gdal` (conda-forge)

## Sounding_Processing [Python]
Acquiring Wyoming sounding data with the following installed packages:

- [`siphon`](https://github.com/Unidata/siphon)
- [`MetPy`](https://github.com/Unidata/MetPy)

