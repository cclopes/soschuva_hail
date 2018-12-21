#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
https://geonetcast.wordpress.com/2017/04/27/geonetclass-manipulating-goes-16-data-with-python-part-i/
"""

from glob import glob

import sat_functions as sf

# Filepaths and custom variables
shapefile_path = "../Data/GENERAL/shapefiles/"
filenames = glob("../Data/SATELLITE/GOES16/level_2/2017/*")
save_path = "figures/"

# Custom visualization extent and grid spacing
# - South America
extent_sa = [-85., -60., -30., 15.]  # [min lon, min lat, max lon, max lat]
gridspc_sa = 10.0

# - SP Brazil
extent_spbr = [-54., -27., -43., -18.]  # [min lon, min lat, max lon, max lat]
gridspc_spbr = 2.0

for filename in filenames:
    # South America
    (unit, conversion, cpt, minvalue, maxvalue, fig_title,
        fig_name) = sf.get_info_file(filename, fig_type='SA')
    sat_data, extent = sf.read_define_bounds_netcdf(filename, conversion,
                                                    extent_sa)
    sf.plot_save_figure(sat_data, extent, shapefile_path, gridspc_sa, cpt,
                        minvalue, maxvalue, fig_title, unit,
                        save_path + fig_name)
    # SP - Brazil
    (unit, conversion, cpt, minvalue, maxvalue, fig_title,
        fig_name) = sf.get_info_file(filename, fig_type='SP-BR')
    sat_data, extent = sf.read_define_bounds_netcdf(filename, conversion,
                                                    extent_spbr)
    sf.plot_save_figure(sat_data, extent, shapefile_path, gridspc_spbr, cpt,
                        minvalue, maxvalue, fig_title, unit,
                        save_path + fig_name)
