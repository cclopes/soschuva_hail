# -*- coding: utf-8 -*-
"""
MULTIDOPPLER RETRIEVAL FROM 2/3 RADARS

- Specific cases, when hailfall occurred:
    - 2017-11-15 21h40 (SR/FCTH and SR/FCTH/XPOL)
                 21h50 (FCTH/XPOL and SR/FCTH/XPOL)
    - 2017-03-14 18h30 (SR/FCTH)
                 20h (SR/FCTH)
- Plotting wind and reflectivity fields derived

Based on MultiDop Sample Workflow Notebook by Timothy Lang.

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

from glob import glob

import misc_functions as misc
from radar_functions import plot_gridded_wind_dbz_panel

# Custom variables
shp_path = "../Data/GENERAL/shapefiles/sao_paulo"
# - 2017-11-15
xlim = (-47.4, -47.15)
ylim = (-23.1, -22.88)
hailpad = (-47.20541, -23.02940)
zerodeg_height = 4.5
# -- 21h40
path = "2017-11-15_21h40/"
date = path[:-1].replace('_', ' ') + 'Z'
filenames = glob(path + '*.pkl')
cs_lat = (-23.05, -23.01)  # (-23.07, -22.93)
cs_lon = (-47.33, -47.14)  # (-47.19, -47.32)
# -- 21h50
# path = "2017-11-15_21h50/"
# date = path[:-1].replace('_', ' ') + 'Z'
# filenames = glob(path + '*.pkl')
# cs_lat = (-23.03, -23.03)  # (-23.09, -22.99)
# cs_lon = (-47.15, -47.33)  # (-47.28, -47.16)

# Reading/plotting results
for filename in filenames:
    name = filename.split('/')[1].split('_')[0].replace('-', '/').upper()
    grid = misc.open_object(filename)
    plot_gridded_wind_dbz_panel(grid, level=0,
                                lat_index=cs_lat, lon_index=cs_lon, date=date,
                                name_multi=name + ' Multi-Doppler at ',
                                shp_name=shp_path, hailpad_pos=hailpad,
                                zero_height=zerodeg_height, grid_spc=.05,
                                xlim=xlim, ylim=ylim)

# Reading results
# grid_2rad = misc.open_object('2017-11-15_21h50/20171115_fcth-xpol_cf.pkl')
# grid_3rad = misc.open_object('2017-11-15_21h50/20171115_sr-fcth-xpol_cf.pkl')
# print(grid_2rad.fields.keys(), grid_3rad.fields.keys())

# Quick first look
# DZcomp = np.amax(grid_2rad.fields['reflectivity']['data'], axis=0)
#
# fig = plt.figure(figsize=(12, 10))
# fig.set_facecolor('w')
# x, y = np.meshgrid(0.001*grid_2rad.x['data'], 0.001*grid_2rad.y['data'])
# cs = plt.pcolormesh(0.001*grid_2rad.x['data'], 0.001*grid_2rad.y['data'],
#                     DZcomp, vmin=0, vmax=70, cmap='pyart_NWSRef')
# Wcomp = np.amax(grid_2rad.fields['upward_air_velocity']['data'], axis=0)
# plt.contour(x, y, Wcomp, levels=[1, 6, 11, 16, 21], colors=['k', 'k', 'k'])
# plt.xlim(-200, 10)
# plt.ylim(-10, 200)
# plt.colorbar(cs, label='Reflectivity (dBZ)')
# plt.title('Max Reflectivity (filled) and Updrafts (black, 10 m/s)')
# plt.xlabel('Distance east of FCTH (km)')
# plt.ylabel('Distance north of FCTH (km)')

# Focusing on the system
# - 2 RADARS (SR, FCTH)
# mf.calc_plot_wind_dbz(grid_2rad, index=2, lon_index=71, name_base='FCTH',
#                       name_multi='SR/FCTH',
#                       xlim_hv=(-150, -120), ylim_hv=(50, 85),
#                       xlim_vv=(50, 85), ylim_vv=(1, 20))
#
#
# - 3 RADARS (SR, FCTH, XPOL)
# mf.calc_plot_wind_dbz(grid_3rad, index=2, lon_index=71, name_base='FCTH',
#                       name_multi='SR/FCTH/XPOL',
#                       xlim_hv=(-150, -120), ylim_hv=(50, 85),
#                       xlim_vv=(50, 85), ylim_vv=(1, 20))
