# -*- coding: utf-8 -*-
"""
"""

import xarray as xr

from read_process_functions import get_sfc_jets_data, get_cape_shear_data
from plot_functions import plot_sfc_jets, plot_cape_shear
import custom_vars as cv


for filename_plevs, filename_sfc in zip(cv.filenames_plevs, cv.filenames_sfc):
    print('--- Processing files ' + filename_sfc + ' ---')
    print('--- and ' + filename_plevs + ' ---')
    # Open files
    ds_plevs = xr.open_dataset(filename_plevs)
    ds_sfc = xr.open_dataset(filename_sfc)

    for t in range(0, 24):
        subds_plevs = ds_plevs.isel(time=t)
        subds_sfc = ds_sfc.isel(time=t)

        print('--- Plotting Surface and Jets, t = ' + str(t) + ' ---')
        plot_data = get_sfc_jets_data(subds_plevs, subds_sfc)
        plot_sfc_jets(plot_data, cv.params_sa)
        plot_sfc_jets(plot_data, cv.params_sp)

        print('--- Plotting CAPE and Shear, t = ' + str(t) + ' ---')
        plot_data = get_cape_shear_data(subds_plevs, subds_sfc)
        plot_cape_shear(plot_data, cv.params_sa)
        plot_cape_shear(plot_data, cv.params_sp)


# for filename_plevs, filename_sfc in zip(cv.filenames_plevs, cv.filenames_sfc):
#     print('--- Processing files ' + filename_sfc + ' ---')
#     # Open files
#     ds_plevs = xr.open_dataset(filename_plevs)
#     ds_sfc = xr.open_dataset(filename_sfc)
#
#     for t in range(0, 24):
#         subds_plevs = ds_plevs.isel(time=t)
#         subds_sfc = ds_sfc.isel(time=t)
#
#         print('--- Plotting CAPE and Shear, t = ' + str(t) + ' ---')
#         plot_data = get_cape_shear_data(subds_plevs, subds_sfc)
#         plot_cape_shear(plot_data, cv.params_sa)
#         plot_cape_shear(plot_data, cv.params_sp)
