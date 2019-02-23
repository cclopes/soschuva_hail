# -*- coding: utf-8 -*-
"""
"""

import numpy as np
import scipy.ndimage as ndimage

import metpy.calc as mpcalc


class ReturnList(object):
    def __init__(self, lat, lon, title_plot, title_figure, mslp,
                 z, thick, cape, cin, wind, u, v):
        self.lat = lat
        self.lon = lon
        self.title_plot = title_plot
        self.title_figure = title_figure
        self.mslp = mslp
        self.z = z
        self.thick = thick
        self.cape = cape
        self.cin = cin
        self.wind = wind
        self.u = u
        self.v = v


def get_main_data(data):
    """
    """

    lat = data['latitude']
    lon = data['longitude']  # - 180
    date_full = data['time'].values
    date = np.datetime_as_string(date_full, unit='s').partition('T')[0]
    time = np.datetime_as_string(date_full, unit='s').partition('T')[2]
    time = time.replace(":", "")[:-2]

    return lat, lon, date, time


def calc_filter_geo_height(geopotential, filter=True):
    """
    """

    z = geopotential/9.81/10
    if filter:
        z = ndimage.gaussian_filter(z, sigma=3, order=0)
    return z


def calc_filter_wind_speed(u, v, filter=True):
    """
    """

    wind = mpcalc.wind_speed(u, v)
    if filter:
        wind = ndimage.gaussian_filter(wind, sigma=3, order=0)
    return wind


def calc_filter_thickness(z_up, z_down, filter=True):
    """
    """

    thick = (z_up - z_down)
    if filter:
        thick = ndimage.gaussian_filter(thick, sigma=3, order=0)
    return thick


def calc_wind_shear(u_up, v_up, u_down, v_down):
    """
    """

    u = u_up - u_down
    v = v_up - v_down
    return u, v


def get_sfc_jets_data(data_plevs, data_sfc, **kwargs):
    """
    """

    lat, lon, date, time = get_main_data(data_plevs)
    # title_plot = ('MSLP (hPa), 1000-500hPa Thickness (dam)\n' +
    #               date + ' ' + time + ' UTC')
    title_plot = ('PNMM (hPa), Espessura 1000-500hPa (dam)\n' +
                  date + ' ' + time + ' UTC')  # pt-br
    title_figure = ('_sfc-jets_' + date.replace('-', '') + time)

    wind = calc_filter_wind_speed(data_plevs['u'].sel(level=250),
                                  data_plevs['v'].sel(level=250))
    mslp = ndimage.gaussian_filter(data_sfc['msl'], sigma=3, order=0)/100
    thick = calc_filter_thickness(
        calc_filter_geo_height(data_plevs['z'].sel(level=500), filter=False),
        calc_filter_geo_height(data_plevs['z'].sel(level=1000), filter=False)
    )

    return ReturnList(
        lat=lat, lon=lon, title_plot=title_plot, title_figure=title_figure,
        mslp=mslp, z=None, thick=thick, cape=None, cin=None, wind=wind,
        u=None, v=None
        )


def get_cape_shear_data(data_plevs, data_sfc, **kwargs):
    """
    """

    lat, lon, date, time = get_main_data(data_plevs)
    # title_plot = (
    #     '850hPa Geo. Height (dam), 1000-500hPa Shear (kt)\n' +
    #     date + ' ' + time + ' UTC')
    title_plot = (
        'Alt. Geo. 850hPa (dam), Cisalhamento 1000-500hPa (kt)\n' +
        date + ' ' + time + ' UTC')  # pt-br
    title_figure = ('_cape-shear_' + date.replace('-', '') + time)

    z = calc_filter_geo_height(data_plevs['z'].sel(level=850))
    cape = ndimage.gaussian_filter(data_sfc['cape'], sigma=3, order=0)
    cin = ndimage.gaussian_filter(data_sfc['cin'], sigma=3, order=0)
    u, v = calc_wind_shear(
        data_plevs['u'].sel(level=500), data_plevs['v'].sel(level=500),
        data_plevs['u'].sel(level=1000), data_plevs['v'].sel(level=1000))

    return ReturnList(
        lat=lat, lon=lon, title_plot=title_plot, title_figure=title_figure,
        mslp=None, z=z, thick=None, cape=cape, cin=cin, wind=None,
        u=u.data, v=v.data
        )
