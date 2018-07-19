#!/usr/bin/env python
# -*- coding: utf-8 -*-

from cpt_convert import loadCPT

def extract_band_info(Band):
    '''
    Create strings with:
    - Central wavelength (Center_WL)
    - Variable units (Unit)
    - Conversion (K to Celsius) (Conversion)
    - Colortable (CPT)
    - Min and max values in imshow (Min, Max)
    according to the selected band.
    '''

    if Band == '01':
        Center_WL = '(0.47 µm)'
    elif Band == '02':
        Center_WL = '(0.64 µm)'
    elif Band == '03':
        Center_WL = '(0.865 µm)'
    elif Band == '04':
        Center_WL = '(1.378 µm)'
    elif Band == '05':
        Center_WL = '(1.61 µm)'
    elif Band == '06':
        Center_WL = '(2.25 µm)'
    elif Band == '07':
        Center_WL = '(3.90 µm)'
    elif Band == '08':
        Center_WL = '(6.19 µm)'
    elif Band == '09':
        Center_WL = '(6.95 µm)'
    elif Band == '10':
        Center_WL = '(7.34 µm)'
    elif Band == '11':
        Center_WL = '(8.50 µm)'
    elif Band == '12':
        Center_WL = '(9.61 µm)'
    elif Band == '13':
        Center_WL = '(10.35 µm)'
    elif Band == '14':
        Center_WL = '(11.20 µm)'
    elif Band == '15':
        Center_WL = '(12.30 µm)'
    elif Band == '16':
        Center_WL = '(13.30 µm)'

    if int(Band) <= 6:
        Unit = "Reflectance"
        Conversion = 0.
    else:
        Unit = "Brightness Temperature [°C]"
        Conversion = -273.15

    if int(Band) <= 6:
        CPT = loadCPT('../Data/GENERAL/colortables/Square Root Visible Enhancement.cpt')
        Min, Max = 0, 1
    elif int(Band) == 7:
        CPT = loadCPT('../Data/GENERAL/colortables/SVGAIR2_TEMP.cpt')
        Min, Max = -112.15, 56.85
    elif int(Band) > 7 and int(Band) < 11:
        CPT = loadCPT('../Data/GENERAL/colortables/SVGAWVX_TEMP.cpt')
        Min, Max = -112.15, 56.85
    elif int(Band) > 10:
        CPT = loadCPT('../Data/GENERAL/colortables/IR4AVHRR6.cpt')
        Min, Max = -103, 84

    return Center_WL, Unit, Conversion, CPT, Min, Max
