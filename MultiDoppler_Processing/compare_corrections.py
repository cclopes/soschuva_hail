# -*- coding: utf-8 -*-
"""
COMPARING DEALISING CORRECTIONS

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

from datetime import datetime

from radar_functions import plot_dbz_vel_grid
import multidop_functions as mf

# Reading filenames
case = open("2017-11-15_21h40/filenames_uf.txt").read().split('\n')
# Other necessary variables
date = datetime(2017, 11, 15, 12)

# radar1 = mf.read_dealise_region(case[0])
# radar1 = mf.read_dealise_4dd(case[0], date, "SBMT")
radar1 = mf.read_uf(case[0])
for n in range(20):
    try:
        plot_dbz_vel_grid(radar1, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8],
                          name_fig=('figures/corrections/sr_ncorr_sweep' +
                          str(n) + '_20171115_v2.png'))
        plot_dbz_vel_grid(radar1, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8], vel_field='corrected_velocity',
                          name_fig=('figures/corrections/sr_corr_sweep' +
                          str(n) + '_20171115_v2.png'))
    except IndexError:
        pass

# radar2 = mf.read_dealise_region(case_20171115[1], vel_field='velocity')
# radar2 = mf.read_dealise_4dd(case[1], date, "SBMT", vel_field='velocity')
radar2 = mf.read_uf(case[1])
for n in range(20):
    try:
        plot_dbz_vel_grid(radar2, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8],
                          name_fig=('figures/corrections/cth_ncorr_sweep' +
                          str(n) + '_20171115_v2.png'))
        plot_dbz_vel_grid(radar2, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8], vel_field='corrected_velocity',
                          name_fig=('figures/corrections/cth_corr_sweep' +
                          str(n) + '_20171115_v2.png'))
    except IndexError:
        pass

# radar3 = mf.read_dealise_region(case_20171115[2], vel_field='velocity')
# radar3 = mf.read_dealise_4dd(case[2], date, "SBMT", vel_field='velocity')
radar3 = mf.read_uf(case[2])
for n in range(20):
    try:
        plot_dbz_vel_grid(radar3, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8],
                          name_fig=('figures/corrections/xpol_ncorr_sweep' +
                          str(n) + '_20171115_v2.png'))
        plot_dbz_vel_grid(radar3, sweep=n, xlim=[-47.5, -47],
                          ylim=[-23.2, -22.8], vel_field='corrected_velocity',
                          name_fig=('figures/corrections/xpol_corr_sweep' +
                          str(n) + '_20171115_v2.png'))
    except IndexError:
        pass
