# -*- coding: utf-8 -*-
"""
MISCELLANEOUS FUNCTIONS

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import pickle


def save_object(obj, filename):
    """
    Saving python objects in a file.

    Parameters
    ----------
    obj: python object
    filename: name of the saved file
    """

    with open(filename, 'wb') as output:  # Overwrites any existing file.
        pickle.dump(obj, output, pickle.HIGHEST_PROTOCOL)


def open_object(filename):
    """
    Open python object saved in a file.

    Parameters
    ----------
    filename: name of the saved file

    Returns
    -------
    obj: python object
    """

    with open(filename, 'rb') as input:
        obj = pickle.load(input)

    return obj
