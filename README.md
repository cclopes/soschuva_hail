# soschuva_hail
R and Python scripts to read and process weather radar, lightning and other data related to hail cases in SOS-CHUVA Project.

## Radar_Processing [Python, R]
Processing weather radar data in two fronts:
- In Python:
  - Calculate hydrometeor classification (using [`CSU_RadarTools`](https://github.com/CSU-Radarmet/CSU_RadarTools)) and plot with polarimetric variables
  - Plot PPIs of single-pol variables
- In R:
  - Read and view CAPPI data (specially from São Roque radar)

## MultiDoppler_Processing [Python]
Processing doppler data from 2 (or 3) weather radars using [`MultiDop`](https://github.com/nasa/MultiDop).

## PyART_CSURT_Tutorial [Python]
A small tutorial about working with brazilian weather radar data in Python with the following packages:

- [`Py-ART`](https://github.com/ARM-DOE/pyart)
- [`CSU_RadarTools`](https://github.com/CSU-Radarmet/CSU_RadarTools)

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
