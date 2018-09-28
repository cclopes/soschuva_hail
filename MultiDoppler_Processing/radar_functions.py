# -*- coding: utf-8 -*-
"""
GENERAL FUNCTIONS TO DEAL WITH RADAR DATA

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import numpy as np
import matplotlib.pyplot as plt
import pyart

import read_brazil_radar as rbr


def read_radar(filename):
    """
    Open radar file with pyart or derived functions

    Parameters
    ----------
    filename: .mvol or .HDF5 file

    Returns
    -------
    radar: Py-ART radar data
    """

    try:
        # .mvol files
        radar = pyart.aux_io.read_gamic(filename)
    except (AttributeError, TypeError):
        # .HDF5 files
        radar = rbr.read_rainbow_hdf5(filename)
    return radar


def add_field_to_grid_object(field, grid, field_name='Reflectivity',
                             units='dBZ', long_name='Reflectivity',
                             standard_name='Reflectivity',
                             dz_field='reflectivity'):
    """
    Adds a newly created field to the Py-ART radar object. If reflectivity is a
    masked array, make the new field masked the same as reflectivity.
    """

    fill_value = -32768
    masked_field = np.ma.asanyarray(field)
    masked_field.mask = masked_field == fill_value
    if hasattr(grid.fields[dz_field]['data'], 'mask'):
        setattr(masked_field, 'mask',
                np.logical_or(masked_field.mask,
                              grid.fields[dz_field]['data'].mask))
        fill_value = grid.fields[dz_field]['_FillValue']
    field_dict = {'data': masked_field,
                  'units': units,
                  'long_name': long_name,
                  'standard_name': standard_name,
                  '_FillValue': fill_value}
    grid.add_field(field_name, field_dict, replace_existing=True)

    return grid


def plot_dbz_vel_grid(radar, xlim, ylim, sweep=0,
                      dbz_field='corrected_reflectivity',
                      vel_field='velocity',
                      shapepath="../Data/GENERAL/shapefiles/sao_paulo",
                      name_fig='test.png'):
    """
    Plot quick view of reflectivity and velocity data

    Parameters
    ----------
    radar: Py-ART processed radar mapped data
    sweep: PPI angle to be used
    xlim, ylim: plot limits in lon, lat
        (min, max) in degrees
    dbz_field: name of the reflectivity field
    vel_field: name of the velocity field
    shapepath: shapefile data path
    name_fig: path + name of saved figure

    Returns
    -------
    Panel plot
    """

    display = pyart.graph.RadarMapDisplay(radar)
    fig = plt.figure(figsize=(12, 5))

    fig.add_subplot(121)
    display.plot_ppi_map(dbz_field, sweep, vmin=10, vmax=70,
                         shapefile=shapepath,
                         max_lat=ylim[1], min_lat=ylim[0],
                         min_lon=xlim[0], max_lon=xlim[1],
                         lat_lines=np.arange(ylim[0], ylim[1], .25),
                         lon_lines=np.arange(xlim[0], xlim[1], .25),
                         cmap='pyart_NWSRef',
                         colorbar_label=dbz_field + ' (dBZ)')
    fig.add_subplot(122)
    display.plot_ppi_map(vel_field, sweep, vmin=-15, vmax=15,
                         shapefile=shapepath,
                         max_lat=ylim[1], min_lat=ylim[0],
                         min_lon=xlim[0], max_lon=xlim[1],
                         lat_lines=np.arange(ylim[0], ylim[1], .25),
                         lon_lines=np.arange(xlim[0], xlim[1], .25),
                         cmap='pyart_BuDRd18',
                         colorbar_label=vel_field + ' (m/s)')
    plt.savefig(name_fig, dpi=300, bbox_inches='tight')
