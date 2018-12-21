#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
https://geonetcast.wordpress.com/2017/04/27/geonetclass-manipulating-goes-16-data-with-python-part-i/
"""

import numpy as np
from datetime import datetime
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from mpl_toolkits.basemap import Basemap
from netCDF4 import Dataset

from remap import remap
from extracting_band_info import extract_band_info


def get_info_file(filename, fig_type):
    """
    Using the name of the NetCDF file (filename), extract:

    According to the band:
    band_unit, unit of the variable to be shown on the plot
    band_conversion, value to be added to convert from Kelvin to Celsius, if
        necessary
    band_cpt, color palette of the variable for the plot
    band_minvalue, minimum value of the variable for the plot
    band_maxvalue, maximum value of the variable for the plot
    title, string to be used on the plot title
    name, string to define the name of the saved figure
    """

    print('Getting info from ' + filename)

    band = (filename[filename.find('M3C') + 3:filename.find('_G16')])
    (band_cw, band_unit, band_conversion, band_cpt, band_minvalue,
        band_maxvalue) = extract_band_info(band)

    start_timestamp = (filename[filename.find('_s') + 2:filename.find('_e')])
    start_timestamp = datetime.strptime(start_timestamp[:13], '%Y%j%H%M%S')
    end_timestamp = (filename[filename.find('_e') + 2:filename.find('_c')])
    end_timestamp = datetime.strptime(end_timestamp[:13], '%Y%j%H%M%S')
    title = ('GOES-16 ABI Band ' + band + ' ' + band_cw +
             '\n Scan from ' +
             datetime.strftime(start_timestamp, '%Y-%m-%d %H%M%S') + ' to ' +
             datetime.strftime(end_timestamp, '%H%M%S') + ' UTC')
    name = ('Band_' + band + '/GOES16_B' + band + '_' + fig_type + '_SD' +
            datetime.strftime(start_timestamp, '%Y%m%d%H%M') + '.png')

    return (band_unit, band_conversion, band_cpt, band_minvalue,
            band_maxvalue, title, name)


def read_define_bounds_netcdf(file, band_conversion, extent):
    """
    Using the NetCDF file:

    Read with ncdf4 to extract information about the data extent
    Regrid to rectangular projection using remap
    ATTENTION: If the files are from the Operational Mode (starting December
        2017), remap.py should be altered! (line 15)
    """

    print('Reading NetCDF file ' + file)

    nc = Dataset(file)

    # Visualization extent for Full Disk
    # geo_extent = nc.variables['geospatial_lat_lon_extent']
    # min_lon = float(geo_extent.geospatial_westbound_longitude)
    # max_lon = float(geo_extent.geospatial_eastbound_longitude)
    # min_lat = float(geo_extent.geospatial_southbound_latitude)
    # max_lat = float(geo_extent.geospatial_northbound_latitude)
    # extent = [min_lon, min_lat, max_lon, max_lat]

    resolution = 2

    # Image extent required for the reprojection
    H = nc.variables['goes_imager_projection'].perspective_point_height
    x1 = nc.variables['x_image_bounds'][0] * H  # x1 = -5434894.885056
    x2 = nc.variables['x_image_bounds'][1] * H  # x2 = 5434894.885056
    y1 = nc.variables['y_image_bounds'][1] * H  # y1 = -5434894.885056
    y2 = nc.variables['y_image_bounds'][0] * H  # y2 = 5434894.885056
    grid = remap(file, extent, resolution, x1, y1, x2, y2)

    data = grid.ReadAsArray() + band_conversion

    return data, extent


def plot_save_figure(data, extent, shapefile, grid_spacing, cpt, min_value,
                     max_value, title, band_unit, name):
    """
    Using data and derived variables:

    Plot using shapefiles ne_10m_admin_0_countries (global) and estadosl_2007
    (Brazilian states), as well as pre-defined spacing according to image
    boundaries (grid_spacing)
    Save the resulting figure with transparent background
    """

    fig = plt.figure(figsize=(5, 6))
    fig.set_facecolor('w')
    ax = fig.add_subplot(111)

    bmap = Basemap(llcrnrlon=extent[0], llcrnrlat=extent[1],
                   urcrnrlon=extent[2], urcrnrlat=extent[3], epsg=4326)

    bmap.readshapefile(
        shapefile + 'ne_10m_admin_0_countries', 'ne_10m_admin_0_countries',
        linewidth=0.5, color='darkslategray'
    )
    bmap.readshapefile(
        shapefile + 'estadosl_2007', 'estadosl_2007', linewidth=0.3,
        color='darkslategray'
    )
    bmap.drawparallels(np.arange(-90.0, 90.0, grid_spacing), linewidth=0.25,
                       color='white', labels=[True, False, False, True])
    bmap.drawmeridians(np.arange(0.0, 360.0, grid_spacing), linewidth=0.25,
                       color='white', labels=[True, False, False, True])

    cpt_convert = LinearSegmentedColormap('cpt', cpt)

    bmap.imshow(data, origin='upper', cmap=cpt_convert,
                vmin=min_value, vmax=max_value)

    plt.title(title, weight='bold', stretch='condensed', size='large')
    bmap.colorbar(location='right', label=band_unit)

    print('Saving figure in ' + name)
    plt.savefig(name, dpi=300, transparent=True, bbox_inches='tight')
    plt.close()

    return '-----------------------------------------------------------------'
