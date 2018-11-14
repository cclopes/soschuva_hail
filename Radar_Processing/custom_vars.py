# -*- coding: utf-8 -*-
"""
CUSTOM VARIABLES FOR RADAR PROCESSING

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""
import matplotlib.colors as colors

path = "../Data/RADAR/"
# 2017-11-15
# - 21h40
# filename = path + "CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115214004.HDF5"
# # filename = (path +
# #             "CTH/level_0_mod/2017-11-15/20171115_214004_XXXXXXXX_v001_PPI.uf")
# date_name = '2017-11-15 21h40Z'
# cs_lat, cs_lon = (-23.05, -23.01), (-47.33, -47.14)
# (-23.07, -22.93), (-47.19, -47.32)
# - 21h50
# filename = path + "CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115215004.HDF5"
# # filename = (path +
# #             "CTH/level_0_mod/2017-11-15/20171115_215004_XXXXXXXX_v001_PPI.uf")
# date_name = '2017-11-15 21h50Z'
# cs_lat, cs_lon = (-23.03, -23.03), (-47.15, -47.33)
# (-23.09, -22.99), (-47.28, -47.16)
# for both times
# grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
# grid_shape = (20, 411, 411)
# grid_spacing = 500.0
# xlim, ylim = (-47.4, -47.15), (-23.1, -22.88)
# hailpad = (-47.20541, -23.02940)
# zerodeg_height = 4.5
# fortydeg_height = 10.2
# sounding_name = "../Data/SOUNDINGS/83779_2017111512Z.txt"
# plotgrid_spc = .07

# 2017-03-14
# - 18h20
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314181729.HDF5"
# date_name = '2017-03-14 18h17Z'
# cs_lat, cs_lon = (-22.82, -22.58), (-47.26, -47.02)
# xlim, ylim = (-47.4, -46.8), (-23, -22.55)
# hailpad = (-47.13110, -22.69160)
# - 18h30
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314182730.HDF5"
# date_name = '2017-03-14 18h27Z'
# cs_lat, cs_lon = (-22.85, -22.57), (-47.25, -47.02)
# xlim, ylim = (-47.45, -46.8), (-23, -22.5)
# hailpad = (-47.13110, -22.69160)
# - 19h50
# filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314194729.HDF5"
# date_name = '2017-03-14 19h47Z'
# cs_lat, cs_lon = (-23.14, -22.8), (-47.17, -47.29)
# # (-23.06, -23.01), (-47.07, -47.28)
# xlim, ylim = (-47.7, -47), (-23.2, -22.65)
# hailpad = (-47.20541, -23.02940)
# - 20h
filename = path + "CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314195729.HDF5"
date_name = '2017-03-14 19h57Z'
cs_lat, cs_lon = (-23.15, -22.78), (-47.15, -47.32)
xlim, ylim = (-47.7, -47), (-23.25, -22.7)
hailpad = (-47.20541, -23.02940)
# - for both times
grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
grid_shape = (20, 411, 411)
grid_spacing = 500.0
zerodeg_height = 5.1
fortydeg_height = 10.6
sounding_name = "../Data/SOUNDINGS/83779_2017031512Z.txt"
plotgrid_spc = .15

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
