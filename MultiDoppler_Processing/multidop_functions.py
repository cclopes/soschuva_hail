# -*- coding: utf-8 -*-
"""
MULTIDOPPLER AUXILIARY FUNCTIONS

- read_dealise_radar()
- grid_radar()
- plot_gridded_radar()
- calc_plot_wind_dbz()

Based on MultiDop Sample Workflow Notebook by Timothy Lang.

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import time
from copy import deepcopy

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import cm

import pyart
import multidop

from radar_functions import read_radar


def read_dealise_radar(filename, dbz_field='corrected_reflectivity',
                       vel_field='corrected_velocity'):

    """
    Reading radar data with radar_funs and:
    - Dealise data with pyart
    - Add a mising_value (and _FillValue if not available) field inside
      reflectivity (DT) and velocity (VT) fields
      
    Parameters
    ----------
    filename: .mvol or .HDF5 file
    dbz_field: name of the reflectivity field to be used
    vel_field: name of the velocity field to be used

    Returns
    -------
    radar: dealised Py-ART radar data
    """

    # Reading
    radar = read_radar(filename)

    # Dealising
    cp = deepcopy(radar.fields[dbz_field]['data'])
    radar.add_field_like(dbz_field, 'DT', cp, replace_existing=True)
    gatefilter = pyart.correct.GateFilter(radar)
    gatefilter.exclude_masked(dbz_field)
    corr_vel = pyart.correct.dealias_region_based(radar, vel_field=vel_field,
                                                  keep_original=False,
                                                  gatefilter=gatefilter,
                                                  centered=True)
    radar.add_field('VT', corr_vel, replace_existing=True)

    # missing_value
    try:
        radar.fields['DT']['missing_value'] = [1.0 *
                                               radar.fields['DT']['_FillValue']]
        radar.fields['VT']['missing_value'] = [1.0 *
                                               radar.fields['VT']['_FillValue']]
    except KeyError:
        radar.fields['DT']['_FillValue'] = radar.fields['DT']['data'].fill_value
        radar.fields['DT']['missing_value'] = [1.0 *
                                               radar.fields['DT']['_FillValue']]
        radar.fields['VT']['_FillValue'] = radar.fields['VT']['data'].fill_value
        radar.fields['VT']['missing_value'] = [1.0 *
                                               radar.fields['VT']['_FillValue']]

    return radar


def grid_radar(radar, grid_shape=(20, 301,  301),
               xlim=(-150000, 150000), ylim=(-150000, 150000),
               zlim=(1000, 20000), fields=['DT', 'VT'], origin=None):

    """
    Using radar data:
    - Create a gridded version (grid) with pyart
    - Add azimuth and elevation information as fields of grid using multidop

    Parameters
    ----------
    radar: Py-ART radar data
    grid_shape: grid shape specifications
        (# points in z, # points in y, # points in x)
    xlim, ylim, zlim: plot limits in x, y, z
        (min, max) in meters
    fields: name of the reflectivity and velocity fields
    origin: custom grid origin
    
    Returns
    -------
    grid: gridded radar data
    """

    # Count the time
    bt = time.time()

    radar_list = [radar]

    if origin is None:
        origin = (radar.latitude['data'][0], radar.longitude['data'][0])

    grid = pyart.map.grid_from_radars(radar_list,
                                      grid_shape=grid_shape,
                                      grid_limits=(zlim, ylim, xlim),
                                      grid_origin=origin,
                                      fields=fields,
                                      gridding_algo='map_gates_to_grid',
                                      grid_origin_alt=0.0)
    grid = multidop.angles.add_azimuth_as_field(grid)
    grid = multidop.angles.add_elevation_as_field(grid)

    print(time.time()-bt, ' seconds to grid radar')

    return grid


def plot_gridded_maxdbz(grid, name_radar, name_base,
                        xlim=[-150000, 150000], ylim=[-150000, 150000]):
    """
    Using gridded radar data, plot max reflectivity field using matplotlib

    Parameters
    ----------
    grid: gridded radar data
    name_radar: name of the radar to be plotted
    name_base: name of the radar whose grid is based on
    xlim, ylim: plot limits in x, y
        (min, max) in meters

    Returns
    -------
    Plot
    """

    DZcomp = np.amax(grid.fields['DT']['data'], axis=0)

    fig = plt.figure(figsize=(6, 5))
    x, y = np.meshgrid(grid.x['data'], grid.y['data'])
    cs = plt.pcolormesh(grid.x['data'], grid.y['data'],
                        DZcomp, vmin=0, vmax=75, cmap='pyart_NWSRef')
    plt.xlim(xlim)
    plt.ylim(ylim)
    plt.colorbar(cs, label='Reflectivity (dBZ)')
    plt.title('Max Reflectivity (filled) of ' + name_radar)
    plt.xlabel('Distance east of ' + name_base + '  (m)')
    plt.ylabel('Distance north of ' + name_base + '  (m)')
    plt.show()


def plot_gridded_velocity(grid, name_radar, name_base, height=0,
                          xlim=[-150000, 150000], ylim=[-150000, 150000]):
    """
    Using gridded radar data, plot velocity field in a height using matplotlib

    Parameters
    ----------
    grid: gridded radar data
    name_radar: name of the radar to be plotted
    name_base: name of the radar whose grid is based on
    height: height index
    xlim, ylim: plot limits in x, y
        (min, max) in meters

    Returns
    -------
    Plot
    """

    field = grid.fields['VT']['data'][height]

    fig = plt.figure(figsize=(6, 5))
    x, y = np.meshgrid(grid.x['data'], grid.y['data'])
    cs = plt.pcolormesh(grid.x['data'], grid.y['data'],
                        field, vmin=-15, vmax=15, cmap='pyart_BuDRd18')
    plt.xlim(xlim)
    plt.ylim(ylim)
    plt.colorbar(cs, label='Velocity (m/s)')
    plt.title(('Doppler Velocity of ' + name_radar + ' in ' + str(height + 1) +
               ' km'))
    plt.xlabel('Distance east of ' + name_base + '  (m)')
    plt.ylabel('Distance north of ' + name_base + '  (m)')
    plt.show()


def calc_plot_wind_dbz(grid, lon_index, name_base, name_multi,
                       index=2, thin=2,
                       xlim_hv=(-150, 150), ylim_hv=(-150, 150),
                       xlim_vv=(-150, 150), ylim_vv=(0, 20)):
    """
    Using gridded multidoppler processed data:
    - Select wind data and calculate grids and wind medians
    - Plot horizontal and vertical views
        - In a specific height (defined by index)
        - In a specific longitudinal cross-section (defined by lon_index)

    Parameters
    ----------
    grid: gridded multidoppler processed data
    lon_index: longitude index for cross-section
    name_base: name of the radar whose grid is based on
    name_multi: acronym with all radar names
    index: height of the horizontal view plot
    thin: grid interval to plot wind arrows
    xlim_hv, ylim_hv: plot limits in x, y for horizontal view
        (min, max) in kilometers
    xlim_vv, ylim_vv: plot limits in x, y for vertical view
        (min, max) in kilometers

    Returns
    -------
    Plots
    """

    # Selecting data
    U = grid.fields['eastward_wind']['data']
    V = grid.fields['northward_wind']['data']
    W = grid.fields['upward_air_velocity']['data']
    Z = grid.fields['reflectivity']['data']

    # Defining grids
    x, y = np.meshgrid(0.001*grid.x['data'], 0.001*grid.y['data'])
    y_cs, z_cs = np.meshgrid(0.001*grid.y['data'], 0.001*grid.z['data'])

    # Wind medians - necessary?
    # Um = np.ma.median(U[index])
    # Vm = np.ma.median(V[index])
    # Wm = np.ma.median([W[i][:,lon_index] for i in range(0,20)])

    # Plotting horizontal view

    # - Main figure
    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111)

    # - Reflectivity (shaded)
    cs = ax.pcolormesh(0.001*grid.x['data'], 0.001*grid.y['data'],
                       Z[index], vmin=0, vmax=65, cmap=cm.GMT_wysiwyg)
    plt.colorbar(cs, label='Reflectivity (dBZ)', ax=ax)

    # - Vertical wind (contour)
    cl = plt.contour(x, y, W[index], levels=range(-20, 20),
                     colors=['k'], linewidths=1)
    plt.clabel(cl, inline=1, fontsize=10, fmt='%1.0f', inline_spacing=0.01)

    # - Wind arrows
    winds = ax.quiver(x[::thin, ::thin], y[::thin, ::thin],
                      U[index][::thin, ::thin], V[index][::thin, ::thin],
                      scale=5, units='xy', color='brown', label='Winds (m/s)')
    ax.quiverkey(winds, 0.8, 0.08, 5, '5 m/s', coordinates='figure')

    # - General aspects
    ax.set_xlim(xlim_hv)
    ax.set_ylim(ylim_hv)
    ax.set_xlabel('Distance East of ' + name_base + ' (km)')
    ax.set_ylabel('Distance North of ' + name_base + ' (km)')
    ax.set_title(name_multi + ' U & V, W (contours, m/s),' +
                 ' & dBZ @ ' + str(index+1) + ' km MSL')
    plt.show()

    # Plotting vertical view

    # - Main figure
    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111)

    # - Reflectivity (shaded)
    cs = ax.pcolormesh(0.001*grid.y['data'], 0.001*grid.z['data'],
                       [Z[i][:, lon_index] for i in range(0, 20)],
                       vmin=0, vmax=70, cmap=cm.GMT_wysiwyg)
    plt.colorbar(cs, label='Reflectivity (dBZ)', ax=ax)

    # - Vertical wind (contour)
    cl = plt.contour(y_cs, z_cs, [W[i][:, lon_index] for i in range(0, 20)],
                     levels=range(-20, 20), colors=['k'], linewidths=1)
    plt.clabel(cl, inline=1, fontsize=10, fmt='%1.0f', inline_spacing=0.01)

    # - Wind barbs
    wind = ax.quiver(y_cs, z_cs, [V[i][:, lon_index] for i in range(0, 20)],
                     [W[i][:, lon_index] for i in range(0, 20)],
                     scale=5, units='xy', color='brown', label='Winds (m/s)')
    ax.quiverkey(wind, 0.8, 0.08, 5, '5 m/s', coordinates='figure')

    # - General aspects
    ax.set_xlim(xlim_vv)
    ax.set_ylim(ylim_vv)
    ax.set_xlabel('Distance North of ' + name_base + ' (km)')
    ax.set_ylabel('Distance above ' + name_base + ' (km)')
    ax.set_title(name_multi + ' V & W, W (contours, m/s),' +
                 ' & dBZ @ '+str(x[0, lon_index])+' km East of ' + name_base)
    plt.show()
