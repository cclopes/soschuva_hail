#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Mon Sep 24 09:07:29 2018

@author: clopes
"""

import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np
import pandas as pd

import datetime
from siphon.simplewebservice.wyoming import WyomingUpperAir

import metpy.calc as mpcalc
from metpy.cbook import get_test_data
from metpy.plots import add_metpy_logo, Hodograph, SkewT
from metpy.units import units

date = datetime.datetime(2017, 11, 15, 12)
sounding = WyomingUpperAir.request_data(date, 'SBMT')
 
#sounding = sounding.dropna(subset=('pressure', 'temperature', 'dewpoint', 'u_wind', 'v_wind'), how='all')
#    p = sounding['pressure'].values
#    T = sounding['temperature'].values * units.degC
#    Td = sounding['dewpoint'].values * units.degC
#    u = sounding['u_wind'].values
#    v = sounding['v_wind'].values
#    date = sounding['time'][1]
#    height = sounding['height'].values
