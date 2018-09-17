# -*- coding: utf-8 -*-
"""
GENERAL FUNCTIONS TO DEAL WITH RADAR DATA

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import pyart

import read_brazil_radar as rbr


def read_radar(filename):
    """
    Open radar file with pyart or derived functions
    """

    try:
        # .mvol files
        radar = pyart.aux_io.read_gamic(filename)
    except AttributeError:
        # .HDF5 files
        radar = rbr.read_rainbow_hdf5(filename)
    return radar
