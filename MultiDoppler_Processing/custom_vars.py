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
# # -- plot_multidop
# cs_lat, cs_lon = (-23.05, -23.01), (-47.33, -47.14)
# # (-23.07, -22.93), (-47.19, -47.32)
# - 21h50
path = "cases/2017-11-15_21h50/"
# -- plot_multidop
cs_lat, cs_lon = (-23.03, -23.03), (-47.15, -47.33)
# (-23.09, -22.99), (-47.28, -47.16)
# - for both scripts
date = datetime(2017, 11, 15, 12)
station = "SBMT"
# - run_multidop
grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
grid_shape = (20, 211, 211)
grid_spacing = 1000.0
# - plot_multidop
xlim, ylim = (-47.4, -47.15), (-23.1, -22.88)
hailpad = (-47.20541, -23.02940)
zerodeg_height = 4.5
fortydeg_height = 10.2

# 2017-03-14
# - 18h30
path = "cases/2017-03-14_18h30/"
# # -- plot_multidop
cs_lat, cs_lon = (-23.05, -23.01), (-47.33, -47.14)
xlim, ylim = (-47.5, -46.75), (-23, -22.4)
hailpad = (-47.20541, -23.02940)
# # (-23.07, -22.93), (-47.19, -47.32)
# - 20h
# path = "cases/2017-03-14_20h00/"
# -- plot_multidop
# cs_lat, cs_lon = (-23.03, -23.03), (-47.15, -47.33)
# xlim, ylim = (-47.7, -47), (-23.3, -22.75)
# hailpad = (-47.20541, -23.02940)
# (-23.09, -22.99), (-47.28, -47.16)
# - for both scripts
date = datetime(2017, 3, 14, 12)
station = "SBMT"
# - run_multidop
grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
grid_shape = (20, 211, 211)
grid_spacing = 1000.0
# - plot_multidop
zerodeg_height = 4.5
fortydeg_height = 10.2

# General
# -- run_multidop
filenames_uf = open(path + "filenames_uf.txt").read().split('\n')
dda_path = '/home/camila/Documentos/MultiDop-master/src/DDA'

# -- plot_multidop
date_name = path[6:-1].replace('_', ' ') + 'Z'
filenames_pkl = glob(path + '*.pkl')
shp_path = "../Data/GENERAL/shapefiles/sao_paulo"
