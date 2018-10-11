# -*- coding: utf-8 -*-
"""
MULTIDOPPLER RETRIEVAL FROM 2/3 RADARS

- Reading radar files for specific cases, when hailfall occurred:
    - 2017-11-15 21h40 (SR/FCTH, SR/XPOL and SR/FCTH/XPOL)
                 21h50 (FCTH/XPOL and SR/FCTH/XPOL)
    - 2017-03-14 18h30 (SR/FCTH)
                 20h (SR/FCTH)
- Executing MultiDop workflow

Based on MultiDop Sample Workflow Notebook by Timothy Lang.

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import time
import tempfile
from datetime import datetime

import pyart
import multidop

import misc_functions as misc
import radar_functions as rf
import multidop_functions as mf
from multidop_parameters import params

# CASE: 2017-11-15

# - Custom variables
path = "2017-11-15_21h40/"
filenames = open(path + "filenames_uf.txt").read().split('\n')
date = datetime(2017, 11, 15, 12)
station = "SBMT"
grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
grid_shape = (20, 211, 211)
grid_spacing = 1000.0

# - Reading data
radar_1 = mf.read_uf(filenames[0])  # SR
radar_2 = mf.read_uf(filenames[1])  # FCTH
radar_3 = mf.read_uf(filenames[2])  # XPOL

# - Gridding based on radar_2 (FCTH)
print('-- Gridding radars --')
grid_1 = rf.grid_radar(radar_1, fields=['DT', 'VT'], for_multidop=True,
                       origin=(radar_2.latitude['data'][0],
                               radar_2.longitude['data'][0]),
                       xlim=grid_xlim, ylim=grid_ylim, grid_shape=grid_shape)
grid_2 = rf.grid_radar(radar_2, fields=['DT', 'VT'], for_multidop=True,
                       origin=(radar_2.latitude['data'][0],
                               radar_2.longitude['data'][0]),
                       xlim=grid_xlim, ylim=grid_ylim, grid_shape=grid_shape)
grid_3 = rf.grid_radar(radar_3, fields=['DT', 'VT'], for_multidop=True,
                       origin=(radar_2.latitude['data'][0],
                               radar_2.longitude['data'][0]),
                       xlim=grid_xlim, ylim=grid_ylim, grid_shape=grid_shape)

# -- Plotting gridded data
# rf.plot_gridded_maxdbz(grid_1, name_radar='SR', name_base='FCTH',
#                        xlim=grid_xlim, ylim=grid_ylim)
# rf.plot_gridded_maxdbz(grid_2, name_radar='FCTH', name_base='FCTH',
#                        xlim=grid_xlim, ylim=grid_ylim)
# rf.plot_gridded_maxdbz(grid_3, name_radar='XPOL', name_base='FCTH',
#                        xlim=grid_xlim, ylim=grid_ylim)
# rf.plot_gridded_velocity(grid_1, name_radar='SR', name_base='FCTH', height=0,
#                          xlim=grid_xlim, ylim=grid_ylim)
# rf.plot_gridded_velocity(grid_2, name_radar='FCTH', name_base='FCTH', height=0,
#                          xlim=grid_xlim, ylim=grid_ylim)
# rf.plot_gridded_velocity(grid_3, name_radar='XPOL', name_base='FCTH', height=0,
#                          xlim=grid_xlim, ylim=grid_ylim)

# - Writing data to file
print('-- Writing grids to NetCDF files --')
pyart.io.write_grid('radar_1.nc', grid_1)
pyart.io.write_grid('radar_2.nc', grid_2)
pyart.io.write_grid('radar_3.nc', grid_3)

# - 2 RADARS (SR, FCTH)
# -- Loading parameters and updating
localfile = tempfile.NamedTemporaryFile()
params['writeout'] = localfile.name

params['x'] = [grid_xlim[0], grid_spacing, grid_shape[1]]
params['y'] = [grid_ylim[0], grid_spacing, grid_shape[1]]
params['z'][1] = grid_spacing
params['grid'] = [grid_1.origin_longitude['data'][0],
                  grid_1.origin_latitude['data'][0], 0.0]
params['radar_names'] = ['SR', 'FCTH']

pf = multidop.parameters.ParamFile(params, 'sr-fcth.dda')
pf = multidop.parameters.CalcParamFile(params, 'calculations.dda')

# -- Executing DDA engine
print('-- Starting DDA engine --')
bt = time.time()
multidop.execute.do_analysis('sr-fcth.dda',
                             cmd_path='/home/camila/Documentos/' +
                             'MultiDop-master/src/DDA')
print((time.time() - bt)/60.0, ' minutes to process')

# -- Writing final grid to a file
# -- Baseline output is not CF or Py-ART compliant. This function fixes that.
final_grid = multidop.grid_io.make_new_grid([grid_1, grid_2],
                                            localfile.name)
misc.save_object(final_grid, path + 'sr-fcth_cf.pkl')
localfile.close()

# - 2 RADARS (SR, XPOL)
# -- Loading parameters and updating
localfile = tempfile.NamedTemporaryFile()
params['writeout'] = localfile.name

params['x'] = [grid_xlim[0], grid_spacing, grid_shape[1]]
params['y'] = [grid_ylim[0], grid_spacing, grid_shape[1]]
params['z'][1] = grid_spacing
params['grid'] = [grid_1.origin_longitude['data'][0],
                  grid_1.origin_latitude['data'][0], 0.0]
params['files'] = ['radar_1.nc', 'radar_3.nc']
params['radar_names'] = ['SR', 'XPOL']

pf = multidop.parameters.ParamFile(params, 'sr-xpol.dda')
pf = multidop.parameters.CalcParamFile(params, 'calculations.dda')

# -- Executing DDA engine
print('-- Starting DDA engine --')
bt = time.time()
multidop.execute.do_analysis('sr-xpol.dda',
                             cmd_path='/home/camila/Documentos/' +
                             'MultiDop-master/src/DDA')
print((time.time() - bt)/60.0, ' minutes to process')

# -- Writing final grid to a file
# -- Baseline output is not CF or Py-ART compliant. This function fixes that.
final_grid = multidop.grid_io.make_new_grid([grid_1, grid_3],
                                            localfile.name)
misc.save_object(final_grid, path + 'sr-xpol_cf.pkl')
localfile.close()

# - 2 RADARS (FCTH, XPOL)
# -- Loading parameters and updating
localfile = tempfile.NamedTemporaryFile()
params['writeout'] = localfile.name

params['x'] = [grid_xlim[0], grid_spacing, grid_shape[1]]
params['y'] = [grid_ylim[0], grid_spacing, grid_shape[1]]
params['z'][1] = grid_spacing
params['grid'] = [grid_1.origin_longitude['data'][0],
                  grid_1.origin_latitude['data'][0], 0.0]
params['files'] = ['radar_2.nc', 'radar_3.nc']
params['radar_names'] = ['FCTH', 'XPOL']

pf = multidop.parameters.ParamFile(params, 'fcth-xpol.dda')
pf = multidop.parameters.CalcParamFile(params, 'calculations.dda')

# -- Executing DDA engine
print('-- Starting DDA engine --')
bt = time.time()
multidop.execute.do_analysis('fcth-xpol.dda',
                             cmd_path='/home/camila/Documentos/' +
                             'MultiDop-master/src/DDA')
print((time.time() - bt)/60.0, ' minutes to process')

# -- Writing final grid to a file
# -- Baseline output is not CF or Py-ART compliant. This function fixes that.
final_grid = multidop.grid_io.make_new_grid([grid_1, grid_3],
                                            localfile.name)
misc.save_object(final_grid, path + 'fcth-xpol_cf.pkl')
localfile.close()

# - 3 RADARS (SR, FCTH, XPOL)
# --- Loading parameters and updating
localfile = tempfile.NamedTemporaryFile()
params['writeout'] = localfile.name

params['x'] = [grid_xlim[0], grid_spacing, grid_shape[1]]
params['y'] = [grid_ylim[0], grid_spacing, grid_shape[1]]
params['z'][1] = grid_spacing
params['grid'] = [grid_1.origin_longitude['data'][0],
                  grid_1.origin_latitude['data'][0], 0.0]
params['files'] = ['radar_1.nc', 'radar_2.nc', 'radar_3.nc']
params['radar_names'] = ['SR', 'FCTH', 'XPOL']

pf = multidop.parameters.ParamFile(params, 'sr-fcth-xpol.dda')
pf = multidop.parameters.CalcParamFile(params, 'calculations.dda')

# -- Executing DDA engine
print('-- Starting DDA engine --')
bt = time.time()
multidop.execute.do_analysis('sr-fcth-xpol.dda',
                             cmd_path='/home/camila/Documentos/' +
                             'MultiDop-master/src/DDA')
print((time.time() - bt)/60.0, ' minutes to process')

# -- Writing final grid to a file
# -- Baseline output is not CF or Py-ART compliant. This function fixes that.
final_grid = multidop.grid_io.make_new_grid([grid_1, grid_2, grid_3],
                                            localfile.name)
# final_grid.write('20171115_sr-fcth-xpol_cf.nc')
misc.save_object(final_grid, path + 'sr-fcth-xpol_cf.pkl')
localfile.close()
