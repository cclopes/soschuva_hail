# -*- coding: utf-8 -*-
"""
MULTIDOPPLER AUXILIARY FUNCTIONS

- read_dealise_radar()
- grid_radar()
- plot_gridded_radar()
- calc_plot_wind_dbz()
- plot_wind_dbz_panel()

Based on MultiDop Sample Workflow Notebook by Timothy Lang.

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

from radar_functions import read_radar, add_field_to_grid_object


def read_uf(filename):
    """
    Reading radar data with Py-ART and:
    - Copying reflectivity and velocity fields as "DT" and "VT", respectively
    - Add a mising_value (and _FillValue if not available) field inside
      DT and VT fields

    Parameters
    ----------
    filename: .uf file

    Returns
    -------
    radar: Py-ART radar data
    """

    radar = pyart.io.read_uf(filename)

    cp = deepcopy(radar.fields['corrected_reflectivity']['data'])
    radar.add_field_like('corrected_reflectivity', 'DT', cp,
                         replace_existing=True)
    cp = deepcopy(radar.fields['corrected_velocity']['data'])
    radar.add_field_like('corrected_velocity', 'VT', cp,
                         replace_existing=True)

    # Adding missing_value
    try:
        radar.fields['DT']['missing_value'] = [
            1.0 * radar.fields['DT']['_FillValue']]
        radar.fields['VT']['missing_value'] = [
            1.0 * radar.fields['VT']['_FillValue']]
    except KeyError:
        radar.fields['DT']['_FillValue'] = (
            radar.fields['DT']['data'].fill_value)
        radar.fields['DT']['missing_value'] = [
            1.0 * radar.fields['DT']['_FillValue']]
        radar.fields['VT']['_FillValue'] = (
            radar.fields['VT']['data'].fill_value)
        radar.fields['VT']['missing_value'] = [
            1.0 * radar.fields['VT']['_FillValue']]

    return radar


def read_dealise_region(filename, dbz_field='corrected_reflectivity',
                        vel_field='corrected_velocity'):

    """
    Reading radar data with radar_funs and:
    - Dealise data with pyart region-based algorithm
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

    # Adding missing_value
    try:
        radar.fields['DT']['missing_value'] = [
            1.0 * radar.fields['DT']['_FillValue']]
        radar.fields['VT']['missing_value'] = [
            1.0 * radar.fields['VT']['_FillValue']]
    except KeyError:
        radar.fields['DT']['_FillValue'] = (
            radar.fields['DT']['data'].fill_value)
        radar.fields['DT']['missing_value'] = [
            1.0 * radar.fields['DT']['_FillValue']]
        radar.fields['VT']['_FillValue'] = (
            radar.fields['VT']['data'].fill_value)
        radar.fields['VT']['missing_value'] = [
            1.0 * radar.fields['VT']['_FillValue']]

    # Defining original and corrected velocity fieds
    if vel_field == 'corrected_velocity':
        radar.add_field_like(vel_field, 'velocity',
                             deepcopy(radar.fields[vel_field]['data']),
                             replace_existing=True)
        radar.add_field_like('VT', vel_field,
                             deepcopy(radar.fields['VT']['data']),
                             replace_existing=True)
    else:
        radar.add_field_like('VT', 'corrected_velocity',
                             deepcopy(radar.fields['VT']['data']),
                             replace_existing=True)

    return radar


def acquire_sounding_wind_data(date, station):
    """
    Get sounding data using siphon, extract necessary variables and return a
    dictionary with heigth and wind data for pyart FourDD algorithm.

    Parameters
    ----------
    date: date of the sounding (datetime.datetime)
    station: name of the METAR sounding station

    Returns
    -------
    d: "dictionary" of sounding wind data
    """

    sounding = WyomingUpperAir.request_data(date, station)
    sounding = sounding.dropna(subset=('height', 'speed', 'direction',
                                       'u_wind', 'v_wind'), how='all')

    height = sounding['height'].values
    speed = sounding['speed'].values
    direction = sounding['direction'].values
    u_wind = sounding['u_wind'].values
    v_wind = sounding['v_wind'].values

    class MyDict(dict):
        pass

    d = MyDict()
    d.height = height
    d.u_wind = u_wind
    d.v_wind = v_wind
    d.speed = speed
    d.direction = direction

    return d


def read_dealise_4dd(filename, date, station,
                     dbz_field='corrected_reflectivity',
                     vel_field='corrected_velocity'):
    """
    Reading radar data with radar_funs and:
    - Dealise data with pyart FourDD algorithm
    - Add a mising_value (and _FillValue if not available) field inside
      reflectivity (DT) and velocity (VT) fields

    Parameters
    ----------
    filename: .mvol or .HDF5 file
    date: date of the sounding (datetime.datetime)
    station: name of the METAR sounding station
    dbz_field: name of the reflectivity field to be used
    vel_field: name of the velocity field to be used

    Returns
    -------
    radar: dealised Py-ART radar data
    """

    # Reading
    radar = read_radar(filename)

    # Getting sounding data
    sounding = acquire_sounding_wind_data(date, station)

    # Dealising
    cp = deepcopy(radar.fields[dbz_field]['data'])
    radar.add_field_like(dbz_field, 'DT', cp, replace_existing=True)
    gatefilter = pyart.correct.GateFilter(radar)
    gatefilter.exclude_transition()
    gatefilter.exclude_invalid(vel_field)
    gatefilter.exclude_invalid(dbz_field)
    gatefilter.exclude_outside(dbz_field, 0, 80)
    corr_vel = pyart.correct.dealias_fourdd(radar, sonde_profile=sounding,
                                            gatefilter=gatefilter,
                                            vel_field=vel_field)
    radar.add_field('VT', corr_vel, replace_existing=True)

    # missing_value
    try:
        radar.fields['DT']['missing_value'] = [
            1.0 * radar.fields['DT']['_FillValue']]
        radar.fields['VT']['missing_value'] = [
            1.0 * radar.fields['VT']['_FillValue']]
    except KeyError:
        radar.fields['DT']['_FillValue'] = (
            radar.fields['DT']['data'].fill_value)
        radar.fields['DT']['missing_value'] = [
            1.0 * radar.fields['DT']['_FillValue']]
        radar.fields['VT']['_FillValue'] = (
            radar.fields['VT']['data'].fill_value)
        radar.fields['VT']['missing_value'] = [
            1.0 * radar.fields['VT']['_FillValue']]

    # Defining original and corrected velocity fieds
    if vel_field == 'corrected_velocity':
        radar.add_field_like(vel_field, 'velocity',
                             deepcopy(radar.fields[vel_field]['data']),
                             replace_existing=True)
        radar.add_field_like('VT', vel_field,
                             deepcopy(radar.fields['VT']['data']),
                             replace_existing=True)
    else:
        radar.add_field_like('VT', 'corrected_velocity',
                             deepcopy(radar.fields['VT']['data']),
                             replace_existing=True)

    return radar
