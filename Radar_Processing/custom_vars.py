# -*- coding: utf-8 -*-
"""
CUSTOM VARIABLES FOR RADAR PROCESSING

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""
import matplotlib.colors as colors

path = "../Data/RADAR/"
hail_flag = True

# 2017-03-14
# - 18h00
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314175729.HDF5"
# date_name = '2017-03-14 1757 UTC'
# cs_lat, cs_lon = (-22.87, -22.6), (-47.17, -47.01)
# xlim, ylim = (-47.4, -46.8), (-23, -22.55)
# hailpad = (-47.13110, -22.69160)
# - 18h05
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314180504.HDF5"
# date_name = '2017-03-14 1805 UTC'
# cs_lat, cs_lon = (-22.83, -22.58), (-47.29, -46.98)
# xlim, ylim = (-47.4, -46.8), (-23, -22.55)
# hailpad = (-47.13110, -22.69160)
# - 18h10
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314181004.HDF5"
# date_name = '2017-03-14 1810 UTC'
# cs_lat, cs_lon = (-22.58, -22.86), (-47.15, -47.1)
# xlim, ylim = (-47.4, -46.8), (-23, -22.55)
# hailpad = (-47.13110, -22.69160)
# - 18h20
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314181729.HDF5"
# date_name = '2017-03-14 1817 UTC'
# cs_lat, cs_lon = (-22.83, -22.58), (-47.29, -46.98)
# xlim, ylim = (-47.4, -46.8), (-23, -22.55)
# hailpad = (-47.13110, -22.69160)
# - 18h30
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314182730.HDF5"
# date_name = '2017-03-14 1827 UTC'
# cs_lat, cs_lon = (-22.85, -22.56), (-47.3, -46.99)
# xlim, ylim = (-47.45, -46.8), (-23, -22.5)
# hailpad = (-47.13110, -22.69160)
# - 19h50
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314194729.HDF5"
# date_name = '2017-03-14 1947 UTC'
# cs_lat, cs_lon = (-22.8, -23.15), (-47.23, -47.19)
# # (-23.06, -23.01), (-47.07, -47.28)
# xlim, ylim = (-47.7, -47), (-23.2, -22.65)
# hailpad = (-47.20541, -23.02940)
# - 20h
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314195729.HDF5"
# date_name = '2017-03-14 1957 UTC'
# cs_lat, cs_lon = (-22.8, -23.17), (-47.23, -47.19)
# xlim, ylim = (-47.7, -47), (-23.25, -22.7)
# hailpad = (-47.20541, -23.02940)
# - for both times
# grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
# grid_shape = (20, 211, 211)
# grid_spacing = 1000.0
# zerodeg_height = 5.1
# fortydeg_height = 10.6
# sounding_name = "../Data/SOUNDINGS/83779_2017031512Z.txt"
# plotgrid_spc = .15

# 2017-11-15
# - 21h30
filename = path + "CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115213004.HDF5"
# filename = (path +
#             "CTH/level_0_mod/2017-11-15/20171115_214004_XXXXXXXX_v001_PPI.uf")
date_name = '2017-11-15 2130 UTC'
cs_lat, cs_lon = (-22.89, -23.02), (-47.36, -47.27)
hail_flag = False
# - 21h40
# filename = path + "CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115214004.HDF5"
# # filename = (path +
# #             "CTH/level_0_mod/2017-11-15/20171115_214004_XXXXXXXX_v001_PPI.uf")
# date_name = '2017-11-15 2140 UTC'
# cs_lat, cs_lon = (-23.01, -23.04), (-47.38, -47.13)
# (-23.07, -22.93), (-47.19, -47.32)
# - 21h50
# filename = path + "CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115215004.HDF5"
# # filename = (path +
# #             "CTH/level_0_mod/2017-11-15/20171115_215004_XXXXXXXX_v001_PPI.uf")
# date_name = '2017-11-15 2150 UTC'
# cs_lat, cs_lon = (-23.03, -23.03), (-47.33, -47.12)
# (-23.09, -22.99), (-47.28, -47.16)
# for both times
grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
grid_shape = (20, 211, 211)
grid_spacing = 1000.0
xlim, ylim = (-47.4, -47.12), (-23.1, -22.88)
hailpad = (-47.20541, -23.02940)
zerodeg_height = 4.5
fortydeg_height = 10.2
sounding_name = "../Data/SOUNDINGS/83779_2017111512Z.txt"
plotgrid_spc = .07

# General
shp_path = "../Data/GENERAL/shapefiles/sao_paulo"
save_path = "figures/ppis/classification/"
cptpath = "../Data/GENERAL/colortables/"

# Custom colorbar for HID plots
hid_colors = ['White', 'LightBlue', 'MediumBlue', 'DarkOrange', 'LightPink',
              'Cyan', 'DarkGray', 'Lime', 'Yellow', 'Red', 'Fuchsia']
cmaphid = colors.ListedColormap(hid_colors)
cmapmeth = colors.ListedColormap(hid_colors[0:6])
cmapmeth_trop = colors.ListedColormap(hid_colors[0:7])
