# -*- coding: utf-8 -*-
"""
MULTIDOPPLER RETRIEVAL FROM 2/3 RADARS

- Reading radar files for specific cases, when hailfall occurred:
    - 2017-11-15 21h40 (SR/FCTH, SR/XPOL and SR/FCTH/XPOL)
    -            21h50 (FCTH/XPOL and SR/FCTH/XPOL)
    - 2017-03-14 18h20 (SR/FCTH)
    -            18h30 (SR/FCTH)
    -            19h50 (SR/FCTH)
    -            20h00 (SR/FCTH)
- Executing PyDDA workflow

Based on PyDDA example on retrieving and plotting winds by Robert Jackson.

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import pyart
import pydda

import misc_functions as misc
import radar_functions as rf
import custom_vars as cv
import pydda_functions as pdf

# - Reading data
radar_1 = pdf.read_uf(cv.filenames_uf[0])  # SR
radar_2 = pdf.read_uf(cv.filenames_uf[1])  # FCTH
radar_3 = pdf.read_uf(cv.filenames_uf[2])  # XPOL

# - Gridding based on radar_2 (FCTH)
print('-- Gridding radars --')
grid_1 = rf.grid_radar(radar_1, fields=['DT', 'VT'], for_multidop=False,
                       origin=(radar_2.latitude['data'][0],
                               radar_2.longitude['data'][0]),
                       xlim=cv.grid_xlim, ylim=cv.grid_ylim,
                       grid_shape=cv.grid_shape)
grid_2 = rf.grid_radar(radar_2, fields=['DT', 'VT'], for_multidop=False,
                       origin=(radar_2.latitude['data'][0],
                               radar_2.longitude['data'][0]),
                       xlim=cv.grid_xlim, ylim=cv.grid_ylim,
                       grid_shape=cv.grid_shape)
grid_3 = rf.grid_radar(radar_3, fields=['DT', 'VT'], for_multidop=False,
                       origin=(radar_2.latitude['data'][0],
                               radar_2.longitude['data'][0]),
                       xlim=cv.grid_xlim, ylim=cv.grid_ylim,
                       grid_shape=cv.grid_shape)

# -- Plotting gridded data
# rf.plot_gridded_maxdbz(grid_1, name_radar='SR', name_base='FCTH',
#                        xlim=cv.grid_xlim, ylim=cv.grid_ylim)
# rf.plot_gridded_maxdbz(grid_2, name_radar='FCTH', name_base='FCTH',
#                        xlim=cv.grid_xlim, ylim=cv.grid_ylim)
# rf.plot_gridded_maxdbz(grid_3, name_radar='XPOL', name_base='FCTH',
#                        xlim=cv.grid_xlim, ylim=cv.grid_ylim)
# rf.plot_gridded_velocity(grid_1, name_radar='SR', name_base='FCTH', height=0,
#                          xlim=cv.grid_xlim, ylim=cv.grid_ylim)
# rf.plot_gridded_velocity(grid_2, name_radar='FCTH', name_base='FCTH', height=0,
#                          xlim=cv.grid_xlim, ylim=cv.grid_ylim)
# rf.plot_gridded_velocity(grid_3, name_radar='XPOL', name_base='FCTH', height=0,
#                          xlim=cv.grid_xlim, ylim=cv.grid_ylim)

# - Writing data to file
# print('-- Writing grids to NetCDF files --')
# pyart.io.write_grid('radar_1.nc', grid_1)
# pyart.io.write_grid('radar_2.nc', grid_2)
# pyart.io.write_grid('radar_3.nc', grid_3)

# - Using sounding as initial condition
sounding = pdf.acquire_sounding_wind_data(cv.date, cv.station)
u_init, v_init, w_init = pydda.initialization.make_wind_field_from_profile(
    grid_2, sounding, vel_field='VT'
)

# - Using constant wind field as initial condition
# u_init, v_init, w_init = pydda.initialization.make_constant_wind_field(
#     grid_2, (0., 0., 0.), vel_field='VT')

# - Using ERA5 data as initial/constraint condition
# u_init, v_init, w_init = pydda.initialization.make_initialization_from_era_interim(
#     grid_2, file_name=cv.era5_file, vel_field='VT')

# - Retrieving!
Grids = pydda.retrieval.get_dd_wind_field(
    [grid_1, grid_2, grid_3], u_init, v_init, w_init, Co=1, Cm=10., Cz=1e-4,
    # Cv=1e-4, Ut=-10., Vt=-10.,
    vel_name='VT', refl_field='DT', frz=cv.zero_height, filt_iterations=0,
    mask_outside_opt=True
)

pyart.io.write_grid('grid1_SR-FCTH-XPOL.nc', Grids[0])
pyart.io.write_grid('grid2_SR-FCTH-XPOL.nc', Grids[1])
pyart.io.write_grid('grid3_SR-FCTH-XPOL.nc', Grids[2])

