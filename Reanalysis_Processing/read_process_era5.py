# -*- coding: utf-8 -*-
"""
"""

import numpy as np
import scipy.ndimage as ndimage
import xarray as xr
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from netCDF4 import Dataset

import metpy
from metpy.units import units
import metpy.calc as mpcalc
import scipy.ndimage as ndimage
