# -*- coding: utf-8 -*-
"""
CUSTOM VARIABLES FOR RADAR PROCESSING

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""
import matplotlib.colors as colors

path = "../Data/RADAR/"
# 2017-11-15
# - 21h40
filename = path + "CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115214004.HDF5"
# filename = (path +
#             "CTH/level_0_mod/2017-11-15/20171115_214004_XXXXXXXX_v001_PPI.uf")
date_name = '2017-11-15 21h40Z'
cs_lat, cs_lon = (-23.05, -23.01), (-47.33, -47.14)
# (-23.07, -22.93), (-47.19, -47.32)
# - 21h50
# filename = path + "CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115215004.HDF5"
# filename = (path +
#             "CTH/level_0_mod/2017-11-15/20171115_215004_XXXXXXXX_v001_PPI.uf")
# date_name = '2017-11-15 21h50Z'
# cs_lat, cs_lon = (-23.03, -23.03), (-47.15, -47.33)
# (-23.09, -22.99), (-47.28, -47.16)
# for both dates
grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
grid_shape = (20, 211, 211)
grid_spacing = 1000.0
xlim, ylim = (-47.4, -47.15), (-23.1, -22.88)
hailpad = (-47.20541, -23.02940)
zerodeg_height = 4.5
fortydeg_height = 10.2
sounding_name = "../Data/SOUNDINGS/83779_2017111512Z.txt"

# General
shp_path = "../Data/GENERAL/shapefiles/sao_paulo"
save_path = "figures/ppis/classification/"

# Custom colorbar for HID plots
hid_colors = ['White', 'LightBlue', 'MediumBlue', 'DarkOrange', 'LightPink',
              'Cyan', 'DarkGray', 'Lime', 'Yellow', 'Red', 'Fuchsia']
cmaphid = colors.ListedColormap(hid_colors)
cmapmeth = colors.ListedColormap(hid_colors[0:6])
cmapmeth_trop = colors.ListedColormap(hid_colors[0:7])
