# -*- coding: utf-8 -*-
"""
COMPARING DEALISING CORRECTIONS

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

from radar_functions import plot_dbz_vel_grid
from multidop_functions import read_dealise_radar

# Reading filenames
case_20171115 = open("filenames_20171115.txt").read().split('\n')
case_20170314 = open("filenames_20170314.txt").read().split('\n')

radar = read_dealise_radar(case_20171115[0])
print(radar.fields.keys())
for n in range(0, 6):
    plot_dbz_vel_grid(radar, sweep=n, xlim=[-47.5, -47], ylim=[-23.2, -22.8],
                      name_fig=('figures/sr_ncorr_sweep' + str(n) +
                                '_20171115.png'))
    plot_dbz_vel_grid(radar, sweep=n, xlim=[-47.5, -47], ylim=[-23.2, -22.8],
                      dbz_field='DT', vel_field='VT',
                      name_fig=('figures/sr_corr_sweep' + str(n) +
                                '_20171115.png'))

radar = read_dealise_radar(case_20171115[1], vel_field='velocity')
print(radar.fields.keys())

for n in range(0, 7):
    plot_dbz_vel_grid(radar, sweep=n, xlim=[-47.5, -47], ylim=[-23.2, -22.8],
                      vel_field='velocity',
                      name_fig=('figures/cth_ncorr_sweep' + str(n) +
                                '_20171115.png'))
    plot_dbz_vel_grid(radar, sweep=n, xlim=[-47.5, -47], ylim=[-23.2, -22.8],
                      dbz_field='DT', vel_field='VT',
                      name_fig=('figures/cth_corr_sweep' + str(n) +
                                '_20171115.png'))

radar = read_dealise_radar(case_20171115[2], vel_field='velocity')
print(radar.fields.keys())
for n in range(0, 16):
    plot_dbz_vel_grid(radar, sweep=n, xlim=[-47.5, -47], ylim=[-23.2, -22.8],
                      vel_field='velocity',
                      name_fig=('figures/xpol_ncorr_sweep' + str(n) +
                                '_20171115.png'))
    plot_dbz_vel_grid(radar, sweep=n, xlim=[-47.5, -47], ylim=[-23.2, -22.8],
                      dbz_field='DT', vel_field='VT',
                      name_fig=('figures/xpol_corr_sweep' + str(n) +
                                '_20171115.png'))
