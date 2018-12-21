# -*- coding: utf-8 -*-
"""
"""

from glob import glob

filenames_plevs = sorted(glob('../Data/REANALYSIS/ERA5/era5_plevs_*'))
filenames_sfc = sorted(glob('../Data/REANALYSIS/ERA5/era5_sfc_*'))

# South America maps
params_sa = {
    'extent': [-85., -30., -60., 15.],  # [min lon, max lon, min lat, max lat]
    'fig_type': 'SA',
    'grid_spacing': 10,
    'cbar_shrink': 0.945,
    'cbar_aspect': 30,
    'shapefiles_path': '../Data/GENERAL/shapefiles/'
}

# SP-BR maps
params_sp = {
    'extent': [-54., -43., -27., -18.],  # [min lon, max lon, min lat, max lat]
    'fig_type': 'SP-BR',
    'grid_spacing': 2,
    'cbar_shrink': 0.565,
    'cbar_aspect': 20,
    'shapefiles_path': '../Data/GENERAL/shapefiles/'
}
