# -*- coding: utf-8 -*-
"""
GENERAL FUNCTIONS TO DEAL WITH RADAR DATA

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import time
from copy import deepcopy

import numpy as np
import numpy.ma as ma
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from mpl_toolkits.basemap import cm

import pyart
import multidop
from siphon.simplewebservice.wyoming import WyomingUpperAir

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

    Parameters
    ----------
    field:
    grid:
    field_name:
    units:
    long_name:
    standard_name:
    dz_field:

    Returns
    -------
    grid:
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


def grid_radar(radar, grid_shape=(20, 301,  301),
               xlim=(-150000, 150000), ylim=(-150000, 150000),
               zlim=(1000, 20000), fields=['reflectivity', 'velocity'],
               origin=None, for_multidop=False):

    """
    Using radar data:
    - Create a gridded version (grid) with pyart
    - (If for_multidop=True) add azimuth and elevation information as fields of
        grid using multidop

    Parameters
    ----------
    radar: Py-ART radar data
    grid_shape: grid shape specifications
        (# points in z, # points in y, # points in x)
    xlim, ylim, zlim: plot limits in x, y, z
        (min, max) in meters
    fields: name of the reflectivity and velocity fields
    origin: custom grid origin
    for_multidop: True if gridded for multidop

    Returns
    -------
    grid: gridded radar data
    """

    # Count the time
    bt = time.time()

    # Fixing linearity
    copy = deepcopy(radar.fields[fields[0]]['data'])
    linear_field = ma.power(10.0, (copy/10.0))
    radar.add_field_like(fields[0], fields[0], linear_field,
                         replace_existing=True)
    radar.fields[fields[0]]['missing_value'] = [
        1.0 * radar.fields[fields[0]]['_FillValue']]
    fields.append(fields[0])

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

    # Fixing linearity
    copy = deepcopy(grid.fields[fields[0]]['data'])
    log_field = 10.0 * ma.log10(copy)
    grid = add_field_to_grid_object(log_field, grid, field_name=fields[0],
                                    dz_field=fields[0])
    grid.fields[fields[0]]['missing_value'] = [
        1.0 * grid.fields[fields[0]]['_FillValue']]

    if for_multidop:
        grid = multidop.angles.add_azimuth_as_field(grid)
        grid = multidop.angles.add_elevation_as_field(grid)

    print(time.time()-bt, ' seconds to grid radar')

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


def calc_plot_gridded_wind_dbz(
        grid, lon_index, name_base, name_multi, index=2, thin=2,
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


def plot_gridded_wind_dbz_panel(
        grid, level, lat_index=None, lon_index=None, date='', name_multi='',
        shp_name='', hailpad_pos=None, zero_height=3., grid_spc=.25,
        xlim=(-48, -46), ylim=(-24, -22)):
    """
    Using gridded multidoppler processed data, plot horizontal and vertical
    views:
    - In a specific height (defined by index)
    - In a specific cross-section (defined by lat_index and lon_index)

    Parameters
    ----------
    grid: gridded multidoppler processed data
    level: level of horizontal plot
    lat_index: tuple of latitude indexes for cross section
        (end, start) in degrees
    lon_index: tuple of longitude indexes for cross section
        (end, start) in degrees
    date: date to be shown on main title
    name_multi: acronym with all radar names
    shp_name: path of shapefiles
    hailpad_pos: tuple of hailpad position
        (lon, lat)
    zero_height: 0 degrees height
    grid_spc: grid spacing for horizontal plot
    xlim, ylim: plot limits in lon, lat for horizontal view
        (min, max) in degrees
    """

    # Getting lat-lon-z points
    lons, lats = grid.get_point_longitude_latitude(level)
    xz, z = np.meshgrid(grid.get_point_longitude_latitude()[0], grid.z['data'])

    # Main figure
    display = pyart.graph.GridMapDisplay(grid)
    fig = plt.figure(figsize=(10, 4), constrained_layout=True)
    gs = GridSpec(nrows=1, ncols=6, figure=fig)

    # - Horizontal view
    print('-- Plotting horizontal view --')
    ax1 = fig.add_subplot(gs[0, :3])
    display.plot_basemap(min_lon=xlim[0], max_lon=xlim[1],
                         min_lat=ylim[0], max_lat=ylim[1],
                         lon_lines=np.arange(xlim[0], xlim[1], grid_spc),
                         lat_lines=np.arange(ylim[0], ylim[1], grid_spc),
                         auto_range=False)
    display.basemap.readshapefile(shp_name, 'sao_paulo', color='gray')
    # -- Reflectivity (shaded)
    display.plot_grid('reflectivity', level, vmin=10, vmax=70,
                      colorbar_flag=False)
    # -- Updraft (contour)
    x, y = display.basemap(lons, lats)
    w = np.amax(grid.fields['upward_air_velocity']['data'], axis=0)
    cl = display.basemap.contour(x, y, w, linewidths=0.5, colors='black')
    plt.clabel(cl, inline=1, fontsize=10, fmt='%1.0f', inline_spacing=0.01)
    # -- Hailpad position
    display.basemap.plot(hailpad_pos[0], hailpad_pos[1], 'kX', markersize=15,
                         markerfacecolor='None', latlon=True)
    # -- Cross section position
    display.basemap.plot(lon_index, lat_index, 'k--', latlon=True)

    # - Vertical view
    print('-- Plotting vertical view --')
    ax2 = fig.add_subplot(gs[0, 3:])
    # -- Reflectivity (shaded)
    display.plot_latlon_slice('reflectivity',
                              coord1=(lon_index[0], lat_index[0]),
                              coord2=(lon_index[1], lat_index[1]),
                              vmin=10, vmax=70, zerodeg_height=zero_height)
    # -- Updraft (contour)
    display.plot_latlon_slice('upward_air_velocity',
                              coord1=(lon_index[0], lat_index[0]),
                              coord2=(lon_index[1], lat_index[1]),
                              plot_type='contour', colorbar_flag=False)
    # -- Wind vectors
    display.plot_latlon_slice('northward_wind', field_2='upward_air_velocity',
                              coord1=(lon_index[0], lat_index[0]),
                              coord2=(lon_index[1], lat_index[1]),
                              plot_type='quiver', colorbar_flag=False)

    # - General aspects
    plt.suptitle(name_multi + date, weight='bold',
                 stretch='condensed', size='x-large')
    ax1.set_title(str(level+1) + ' km ' 'Reflectivity, Max Updrafts (m/s)')
    ax2.set_title('Cross Section Reflectivity, Updrafts (m/s)')
    ax2.set_xlabel('')
    ax2.set_ylabel('Distance above Ground (km)')
    ax2.grid(linestyle='-', linewidth=0.25)
    plt.savefig('figures/' + name_multi.split(' ')[0].replace('/', '-') + ' ' +
                date + '.png', dpi=300, bbox_inches='tight')
