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

import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
from cartopy.io.shapereader import Reader
from cartopy.feature import ShapelyFeature

import pyart
import pydda

import custom_vars as cv


Grids = [pyart.io.read_grid('grid1_SR-FCTH-XPOL.nc'),
         pyart.io.read_grid('grid2_SR-FCTH-XPOL.nc'),
         pyart.io.read_grid('grid3_SR-FCTH-XPOL.nc')]

shp_name = cv.shp_path + '.shp'

# plt.figure(figsize=(7,6))
# pydda.vis.plot_horiz_xsection_barbs(Grids, None, 'DT', level=1,
#                                     vmin=0, vmax=70,
#                                     barb_spacing_x_km=5.,
#                                     barb_spacing_y_km=5.)
# # plt.vlines(-65., 50, 90, linestyles='dashed', colors='k')
# plt.hlines(63., -150, -120, linestyles='dashed', colors='k')
# plt.xlim((-150, -120))
# plt.ylim((50, 80))
# plt.show()

plt.figure(figsize=(7,4))
ax = plt.axes(projection=ccrs.PlateCarree())
pydda.vis.plot_horiz_xsection_quiver_map(
    Grids, ax=ax, background_field='DT', level=2, vmin=0, vmax=70,
    w_vel_contours=(5, 45), contour_alpha=0,
    quiver_spacing_x_km=5, quiver_spacing_y_km=5, quiverkey_len=5, quiver_width=0.005)
# ax.add_feature(shape_feature)
ax.add_geometries(Reader(shp_name).geometries(),
                  ccrs.PlateCarree(), facecolor='none', edgecolor='gray')
plt.plot(cv.hailpad[0], cv.hailpad[1], 'kX',
         markersize=15, markerfacecolor='w', alpha=0.75)
ax.set_xlim(cv.xlim)
ax.set_ylim(cv.ylim)
plt.savefig('figures/pydda/horiz_sounding.png', dpi=300, bbox_inches='tight')

# plt.figure(figsize=(7,4))
# # pydda.vis.plot_xz_xsection_barbs(Grids, None, 'DT', level=80,
# #                                  w_vel_contours=[1,3,5,7],
# #                                  barb_spacing_x_km=5.,
# #                                  barb_spacing_z_km=1.)
# # pydda.vis.plot_xz_xsection_streamlines(Grids, None, 'DT', level=80,
# #                                        w_vel_contours=[3,6,9])
# pydda.vis.plot_yz_xsection_quiver(Grids, None, 'DT', level=125-50, vmin=0, vmax=70,
#                                   quiver_spacing_y_km=2, quiver_spacing_z_km=1,
#                                   quiverkey_len=5, quiver_width=0.005)
# plt.xlim((50, 90))
# plt.savefig('figures/pydda/vert_sounding.png', dpi=300, bbox_inches='tight')

plt.figure(figsize=(7,4))
# pydda.vis.plot_xz_xsection_barbs(Grids, None, 'DT', level=80,
#                                  w_vel_contours=[1,3,5,7],
#                                  barb_spacing_x_km=5.,
#                                  barb_spacing_z_km=1.)
pydda.vis.plot_xz_xsection_quiver(Grids, None, 'DT', level=63+10, vmin=0, vmax=70,
                                  quiver_spacing_x_km=2, quiver_spacing_z_km=1,
                                  quiverkey_len=5, quiver_width=0.005)
# pydda.vis.plot_yz_xsection_quiver(Grids, None, 'DT', level=125-50, vmin=0, vmax=70,
#                                   quiver_spacing_y_km=2, quiver_spacing_z_km=1,
#                                   quiverkey_len=5, quiver_width=0.005)
plt.xlim((-150, -120))
plt.savefig('figures/pydda/vert_sounding.png', dpi=300, bbox_inches='tight')
