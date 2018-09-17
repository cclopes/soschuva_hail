# -*- coding: utf-8 -*-
"""
MULTIDOPPLER RETRIEVAL FROM 2/3 RADARS

- Reading radar files for specific cases, when hailfall occurred:
    - 2017-11-15 21h40 (SR/CTH and SR/CTH/XPOL)
    - 2017-03-14 18h30 and 20h (SR/CTH)
- Executing MultiDop workflow
- Plotting wind and reflectivity fields derived

Based on MultiDop Sample Workflow Notebook by Timothy Lang.

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import time
import tempfile

import numpy as np
import matplotlib.pyplot as plt

import pyart
import multidop

import multidop_functions as mf
from multidop_parameters import params


# CASE: 2017-11-15

# - Custom variables
filenames = open("filenames_20171115.txt").read().split('\n')
grid_xlim, grid_ylim = (-200000.0, 10000.0), (-10000.0, 200000.0)
grid_shape = (20, 211, 211)
grid_spacing = 1000.0

# - Reading data
radar_1 = mf.read_dealise_radar(filenames[0])  # SR
radar_2 = mf.read_dealise_radar(filenames[1], vel_field='velocity')  # CTH
radar_3 = mf.read_dealise_radar(filenames[2], vel_field='velocity')  # XPOL

# - Gridding based on radar_2 (CTH)
grid_1 = mf.grid_radar(radar_1,
                       origin=(radar_2.latitude['data'][0],
                               radar_2.longitude['data'][0]),
                       xlim=grid_xlim, ylim=grid_ylim, grid_shape=grid_shape)
grid_2 = mf.grid_radar(radar_2,
                       origin=(radar_2.latitude['data'][0],
                               radar_2.longitude['data'][0]),
                       xlim=grid_xlim, ylim=grid_ylim, grid_shape=grid_shape)
grid_3 = mf.grid_radar(radar_3,
                       origin=(radar_2.latitude['data'][0],
                               radar_2.longitude['data'][0]),
                       xlim=grid_xlim, ylim=grid_ylim, grid_shape=grid_shape)

# mf.plot_gridded_radar(grid_1, name_radar='SR', name_base='CTH',
#                       xlim=grid_xlim/1000.0, ylim=grid_ylim/1000.0)
# mf.plot_gridded_radar(grid_2, name_radar='CTH', name_base='CTH',
#                       xlim=grid_xlim/1000.0, ylim=grid_ylim/1000.0)
# mf.plot_gridded_radar(grid_3, name_radar='XPOL', name_base='CTH',
#                       xlim=grid_xlim/1000.0, ylim=grid_ylim/1000.0)

# - Writing data to file
pyart.io.write_grid('files/radar_1.nc', grid_1)
pyart.io.write_grid('files/radar_2.nc', grid_2)
pyart.io.write_grid('files/radar_3.nc', grid_3)

# - 2 RADARS (SR, CTH)
# -- Loading parameters and updating
localfile = tempfile.NamedTemporaryFile()
params['writeout'] = localfile.name

params['x'] = [grid_xlim[0], grid_spacing, grid_shape[1]]
params['y'] = [grid_ylim[0], grid_spacing, grid_shape[1]]
params['z'][1] = grid_spacing
params['grid'] = [grid_1.origin_longitude['data'][0],
                  grid_1.origin_latitude['data'][0], 0.0]
params['radar_names'] = ['SR', 'CTH']

pf = multidop.parameters.ParamFile(params, 'files/case_20171115_2rad.dda')
pf = multidop.parameters.CalcParamFile(params, 'files/calculations.dda')

# -- Executing DDA engine
bt = time.time()
multidop.execute.do_analysis('files/case_20171115_2rad.dda',
                             cmd_path='src/DDA')
print((time.time() - bt)/60.0, ' minutes to process')

# -- Writing final grid to a file
# -- Baseline output is not CF or Py-ART compliant. This function fixes that.
final_grid = multidop.grid_io.make_new_grid([grid_1, grid_2], localfile.name)
final_grid.write('files/case_20171115_cf_2rad.nc')
localfile.close()

# - 3 RADARS (SR, CTH, XPOL)
# --- Loading parameters and updating
localfile = tempfile.NamedTemporaryFile()
params['writeout'] = localfile.name

params['x'] = [grid_xlim[0], grid_spacing, grid_shape[1]]
params['y'] = [grid_ylim[0], grid_spacing, grid_shape[1]]
params['z'][1] = grid_spacing
params['grid'] = [grid_1.origin_longitude['data'][0],
                  grid_1.origin_latitude['data'][0], 0.0]
params['files'].append('radar_3.nc')
params['radar_names'] = ['SR', 'CTH', 'XPOL']

pf = multidop.parameters.ParamFile(params, 'files/case_20171115_3rad.dda')
pf = multidop.parameters.CalcParamFile(params, 'files/calculations.dda')

# -- Executing DDA engine
bt = time.time()
multidop.execute.do_analysis('files/case_20171115_3rad.dda',
                             cmd_path='src/DDA')
print((time.time() - bt)/60.0, ' minutes to process')

# -- Writing final grid to a file
# -- Baseline output is not CF or Py-ART compliant. This function fixes that.
final_grid = multidop.grid_io.make_new_grid([grid_1, grid_2, grid_3],
                                            localfile.name)
final_grid.write('files/case_20171115_cf_3rad.nc')
localfile.close()

# - Reading/plotting results
grid_2rad = pyart.io.read_grid('files/case_20171115_cf_2rad.nc')
grid_3rad = pyart.io.read_grid('files/case_20171115_cf_3rad.nc')
print(grid_2rad.fields.keys(), grid_3rad.fields.keys())

# -- Quick first look
DZcomp = np.amax(grid_2rad.fields['reflectivity']['data'], axis=0)

fig = plt.figure(figsize=(12, 10))
fig.set_facecolor('w')
x, y = np.meshgrid(0.001*grid_2rad.x['data'], 0.001*grid_2rad.y['data'])
cs = plt.pcolormesh(0.001*grid_2rad.x['data'], 0.001*grid_2rad.y['data'],
                    DZcomp, vmin=0, vmax=75, cmap='pyart_NWSRef')
Wcomp = np.amax(grid_2rad.fields['upward_air_velocity']['data'], axis=0)
plt.contour(x, y, Wcomp, levels=[1, 6, 11, 16, 21], colors=['k', 'k', 'k'])
plt.xlim(-200, 10)
plt.ylim(-10, 200)
plt.colorbar(cs, label='Reflectivity (dBZ)')
plt.title('Max Reflectivity (filled) and Updrafts (black, 10 m/s)')
plt.xlabel('Distance east of CTH (km)')
plt.ylabel('Distance north of CTH (km)')

# -- Focusing on the system
# --- 2 RADARS (SR, CTH)
mf.calc_plot_wind_dbz(grid_2rad, lon_index=71, name_base='CTH',
                      name_multi='SR/CTH')

# --- 3 RADARS (SR, CTH, XPOL)
mf.calc_plot_wind_dbz(grid_3rad, lon_index=71, name_base='CTH',
                      name_multi='SR/CTH/XPOL')
