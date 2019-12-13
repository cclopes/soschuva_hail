# -*- coding: utf-8 -*-
"""
HYDROMETEOR CLASSIFICATION FROM POLARIMETRIC RADAR DATA (Paper Version)

- Reading radar files for specific cases, when hailfall occurred:
    - FCTH (S Band, Dual Pol)
        - corrected_reflectivity
        - cross_correlation_ratio
        - differential_reflectivity
        - specific_differential_phase
    - Cases:
    - 2017-03-14
    - 2017-11-15
- Processing data with CSU_RadarTools
- Classifying into 10 hydrometeor types (Drizzle, Rain, Ice Crystals,
    Aggregates, Wet/Melting Snow, Vertically Aligned Ice, Low-Density Graupel,
    High-Density Graupel, Hail and Big Drops)
- Calculating liquid and ice water mass
- Plotting data

Based on CSU_RadarTools Demonstration Notebook by Timothy Lang.

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import radar_functions as rf
import custom_vars as cv
import custom_cbars


radar = rf.read_radar(cv.filename)
# radar = pyart.io.read_uf(cv.filename)
radar = rf.calculate_radar_hid(radar, cv.sounding_name, "S")
radar.fields['specific_differential_phase']['units'] = r'$\degree\  km^{-1}$'
radar.fields['differential_reflectivity']['units'] = 'dB'
if cv.pt_br:
    radar.fields['cross_correlation_ratio']['units'] = 'adimensional'
    radar.fields['corrected_reflectivity']['standard_name'] = (
        "Refletividade Corrigida")
    radar.fields['FH']['standard_name'] = (
        "IDs de Hidrometeoros")
    radar.fields['MW']['standard_name'] = (
        "Massa de Água Líquida")
    radar.fields['MI']['standard_name'] = (
        "Massa de Gelo")
    radar.fields['cross_correlation_ratio']['standard_name'] = (
        "Razão de Correlação Cruzada")
    radar.fields['differential_reflectivity']['standard_name'] = (
        "Refletividade Diferencial")
    radar.fields['specific_differential_phase']['standard_name'] = (
        "Fase Diferencial Específica")

rf.plot_ppi_panel(
    radar, 'corrected_reflectivity', level=cv.level, fmin=0, fmax=70, azim=cv.azim,
    cmap='dbz', date=cv.date_name, name_multi=cv.name,
    shp_name=cv.shp_path, hailpad_pos=cv.hailpad, hailpad_distance=cv.hailpad_distance,
    zero_height=cv.zerodeg_height, minusforty_height=cv.fortydeg_height,
    grid_spc=cv.plotgrid_spc, xlim=cv.xlim, ylim=cv.ylim, cslim=cv.cs_azim,
    save_path=cv.save_path, index="a", hailpad_cs_flag=cv.hail_flag, pt_br=cv.pt_br)

rf.plot_ppi_panel(
    radar, 'differential_reflectivity', level=cv.level, fmin=-2, fmax=4, azim=cv.azim,
    cmap='zdr', date=cv.date_name, name_multi=cv.name,
    shp_name=cv.shp_path, hailpad_pos=cv.hailpad, hailpad_distance=cv.hailpad_distance,
    zero_height=cv.zerodeg_height, minusforty_height=cv.fortydeg_height,
    grid_spc=cv.plotgrid_spc, xlim=cv.xlim, ylim=cv.ylim, cslim=cv.cs_azim,
    save_path=cv.save_path, index="b", hailpad_cs_flag=cv.hail_flag, pt_br=cv.pt_br)

rf.plot_ppi_panel(
    radar, 'specific_differential_phase', level=cv.level, fmin=-2, fmax=3.2, azim=cv.azim,
    cmap='kdp', date=cv.date_name, name_multi=cv.name,
    shp_name=cv.shp_path, hailpad_pos=cv.hailpad, hailpad_distance=cv.hailpad_distance,
    zero_height=cv.zerodeg_height, minusforty_height=cv.fortydeg_height,
    grid_spc=cv.plotgrid_spc, xlim=cv.xlim, ylim=cv.ylim, cslim=cv.cs_azim,
    save_path=cv.save_path, index="c", hailpad_cs_flag=cv.hail_flag, pt_br=cv.pt_br)

rf.plot_ppi_panel(
    radar, 'cross_correlation_ratio', level=cv.level, fmin=0.8, fmax=1.013, azim=cv.azim,
    cmap='rho', date=cv.date_name, name_multi=cv.name,
    shp_name=cv.shp_path, hailpad_pos=cv.hailpad, hailpad_distance=cv.hailpad_distance,
    zero_height=cv.zerodeg_height, minusforty_height=cv.fortydeg_height,
    grid_spc=cv.plotgrid_spc, xlim=cv.xlim, ylim=cv.ylim, cslim=cv.cs_azim,
    save_path=cv.save_path, index="d", hailpad_cs_flag=cv.hail_flag, pt_br=cv.pt_br)

rf.plot_ppi_panel(
    radar, 'FH', level=cv.level, fmin=0, fmax=10, azim=cv.azim, cmap=cv.cmaphid,
    date=cv.date_name, name_multi=cv.name,
    shp_name=cv.shp_path, hailpad_pos=cv.hailpad, hailpad_distance=cv.hailpad_distance,
    zero_height=cv.zerodeg_height, minusforty_height=cv.fortydeg_height,
    grid_spc=cv.plotgrid_spc, xlim=cv.xlim, ylim=cv.ylim, cslim=cv.cs_azim,
    save_path=cv.save_path, index="a", hailpad_cs_flag=cv.hail_flag, pt_br=cv.pt_br)

rf.plot_ppi_panel(
    radar, 'MW', level=cv.level, fmin=0, fmax=10, azim=cv.azim, cmap='mass',
    date=cv.date_name, name_multi=cv.name,
    shp_name=cv.shp_path, hailpad_pos=cv.hailpad, hailpad_distance=cv.hailpad_distance,
    zero_height=cv.zerodeg_height, minusforty_height=cv.fortydeg_height,
    grid_spc=cv.plotgrid_spc, xlim=cv.xlim, ylim=cv.ylim, cslim=cv.cs_azim,
    save_path=cv.save_path, index="b", hailpad_cs_flag=cv.hail_flag, pt_br=cv.pt_br)

rf.plot_ppi_panel(
    radar, 'MI', level=cv.level, fmin=0, fmax=30, azim=cv.azim, cmap='mass',
    date=cv.date_name, name_multi=cv.name,
    shp_name=cv.shp_path, hailpad_pos=cv.hailpad, hailpad_distance=cv.hailpad_distance,
    zero_height=cv.zerodeg_height, minusforty_height=cv.fortydeg_height,
    grid_spc=cv.plotgrid_spc, xlim=cv.xlim, ylim=cv.ylim, cslim=cv.cs_azim,
    save_path=cv.save_path, index="c", hailpad_cs_flag=cv.hail_flag, pt_br=cv.pt_br)
