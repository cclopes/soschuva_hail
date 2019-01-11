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


import misc_functions as misc
from radar_functions import plot_gridded_wind_dbz_panel
import custom_vars as cv
import custom_cbars

# Reading/plotting results
for filename in cv.filenames_pkl:
    name = filename.split('/')[2].split('_')[0].replace('-', '/').upper()
    grid = misc.open_object(filename)
    plot_gridded_wind_dbz_panel(
        grid, level=2, lat_index=cv.cs_lat, lon_index=cv.cs_lon, cmap='dbz',
        date=cv.date_name, name_multi=name + ' Multi-Doppler at ',
        shp_name=cv.shp_path, hailpad_pos=cv.hailpad,
        zero_height=cv.zerodeg_height, minusforty_height=cv.fortydeg_height,
        grid_spc=cv.plotgrid_spc, xlim=cv.xlim, ylim=cv.ylim, lg_spc=cv.lg_spc,
        index=cv.index)

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
