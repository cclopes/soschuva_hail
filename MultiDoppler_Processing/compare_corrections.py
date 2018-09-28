# -*- coding: utf-8 -*-
"""
COMPARING DEALISING CORRECTIONS

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

from datetime import datetime

from radar_functions import plot_dbz_vel_grid
from multidop_functions import read_dealise_region, read_dealise_4dd

# Reading filenames
case_20171115 = open("filenames_20171115_v2.txt").read().split('\n')
case_20170314 = open("filenames_20170314.txt").read().split('\n')
# Other necessary variables
date = datetime(2017, 11, 15, 12)

#radar1 = read_dealise_region(case_20171115[0])
radar1 = read_dealise_4dd(case_20171115[0], date, "SBMT")
for n in range(20):
    try:
        plot_dbz_vel_grid(radar1, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8],
                          name_fig=('figures/sr_ncorr_sweep' + str(n) +
                                    '_20171115_v2.png'))
        plot_dbz_vel_grid(radar1, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8], vel_field='corrected_velocity',
                          name_fig=('figures/sr_corr_sweep' + str(n) +
                                    '_20171115_v2.png'))
    except IndexError:
        pass

#radar2 = read_dealise_region(case_20171115[1], vel_field='velocity')
radar2 = read_dealise_4dd(case_20171115[1], date, "SBMT", vel_field='velocity')
for n in range(20):
    try:
        plot_dbz_vel_grid(radar2, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8],
                          name_fig=('figures/cth_ncorr_sweep' + str(n) +
                                    '_20171115_v2.png'))
        plot_dbz_vel_grid(radar2, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8], vel_field='corrected_velocity',
                          name_fig=('figures/cth_corr_sweep' + str(n) +
                                    '_20171115_v2.png'))
    except IndexError:
        pass

#radar3 = read_dealise_region(case_20171115[2], vel_field='velocity')
radar3 = read_dealise_4dd(case_20171115[2], date, "SBMT", vel_field='velocity')
for n in range(20):
    try:
        plot_dbz_vel_grid(radar3, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8]
                          name_fig=('figures/xpol_ncorr_sweep' + str(n) +
                                    '_20171115_v2.png'))
        plot_dbz_vel_grid(radar3, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8], vel_field='corrected_velocity',
                          name_fig=('figures/xpol_corr_sweep' + str(n) +
                                    '_20171115_v2.png'))
    except IndexError:
        pass
