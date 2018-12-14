# -*- coding: utf-8 -*-
"""
CUSTOM VARIABLES FOR MULTIDOPPLER PROCESSING

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

from glob import glob
from datetime import datetime

# 2017-11-15
# - 21h40
# path = "cases/2017-11-15_21h40/"
# date_name = '2017-11-15 2140 UTC'
# # -- plot_multidop
# cs_lat, cs_lon = (-23.01, -23.04), (-47.38, -47.13)
# - 21h50
# path = "cases/2017-11-15_21h50/"
# date_name = '2017-11-15 2150 UTC'
# # -- plot_multidop
# cs_lat, cs_lon = (-23.03, -23.03), (-47.33, -47.12)
# - for both scripts
# date = datetime(2017, 11, 15, 12)
# station = "SBMT"
# # - run_multidop
# grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
# grid_shape = (20, 211, 211)
# grid_spacing = 1000.0
# # - plot_multidop
# xlim, ylim = (-47.4, -47.12), (-23.1, -22.88)
# hailpad = (-47.20541, -23.02940)
# zerodeg_height = 4.5
# fortydeg_height = 10.2
# plotgrid_spc = .07
# lg_spc = 0.5

# 2017-03-14
# - 18h20
# path = "cases/2017-03-14_18h20/"
# date_name = '2017-03-14 1820 UTC'
# # -- plot_multidop
# cs_lat, cs_lon = (-22.83, -22.58), (-47.29, -46.98)
# xlim, ylim = (-47.4, -46.8), (-23, -22.55)
# hailpad = (-47.13110, -22.69160)
# - 18h30
# path = "cases/2017-03-14_18h30/"
# date_name = '2017-03-14 1830 UTC'
# # -- plot_multidop
# cs_lat, cs_lon = (-22.85, -22.56), (-47.3, -46.99)
# xlim, ylim = (-47.45, -46.8), (-23, -22.5)
# hailpad = (-47.13110, -22.69160)
# - 19h50
# path = "cases/2017-03-14_19h50/"
# date_name = '2017-03-14 1950 UTC'
# # -- plot_multidop
# cs_lat, cs_lon = (-22.8, -23.15), (-47.23, -47.19)
# xlim, ylim = (-47.7, -47), (-23.2, -22.65)
# hailpad = (-47.20541, -23.02940)
# - 20h
# path = "cases/2017-03-14_20h00/"
# date_name = '2017-03-14 2000 UTC'
# # -- plot_multidop
# cs_lat, cs_lon = (-22.8, -23.17), (-47.23, -47.19)
# xlim, ylim = (-47.7, -47), (-23.25, -22.7)
# hailpad = (-47.20541, -23.02940)
# - for both scripts
# date = datetime(2017, 3, 14, 12)
# station = "SBMT"
# # - run_multidop
# grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
# grid_shape = (20, 211, 211)
# grid_spacing = 1000.0
# # - plot_multidop
# zerodeg_height = 5.1
# fortydeg_height = 10.6
# plotgrid_spc = .15
# lg_spc = 1.

# General
# -- run_multidop
filenames_uf = open(path + "filenames_uf.txt").read().split('\n')
dda_path = '/home/camila/Documentos/MultiDop-master/src/DDA'

# -- plot_multidop
filenames_pkl = glob(path + '*.pkl')
shp_path = "../Data/GENERAL/shapefiles/sao_paulo"
cptpath = "../Data/GENERAL/colortables/"
