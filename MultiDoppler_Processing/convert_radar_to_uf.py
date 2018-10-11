# -*- coding: utf-8 -*-
"""
CREATING CFRADIAL RADAR FILES FOR RADX

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

from datetime import datetime

import pyart

from multidop_functions import read_dealise_region, read_dealise_4dd
from radar_functions import read_radar

# Reading filenames
files = (open("filenames_20171115_21h40.txt").read().split('\n') +
         open("filenames_20171115_21h50.txt").read().split('\n'))
# Other necessary variables
date = datetime(2017, 11, 15, 12)

# Read and correct radar data according to notes
radars = [read_dealise_4dd(files[0], date, "SBMT"),
          read_dealise_4dd(files[1], date, "SBMT", vel_field='velocity'),
          read_radar(files[2]),
          read_dealise_region(files[3]),
          read_dealise_4dd(files[4], date, "SBMT", vel_field='velocity'),
          read_dealise_region(files[5], vel_field='velocity')]

for i in range(len(radars)):
    filename = 'files/' + files[i].split('/')[-1][:-5] + '.uf'
    pyart.io.write_uf(filename, radars[i])
