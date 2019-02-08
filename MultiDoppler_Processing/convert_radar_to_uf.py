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
files = (open("cases/2017-11-15_21h30/filenames.txt").read().split('\n')[:-1])
         # open("cases/2017-03-14_18h30/filenames.txt").read().split('\n')[:-1] +
         # open("cases/2017-03-14_19h50/filenames.txt").read().split('\n')[:-1] +
         # open("cases/2017-03-14_20h00/filenames.txt").read().split('\n')[:-1])
# Other necessary variables
date = datetime(2017, 11, 15, 12)

# Read and correct radar data according to notes
radars = [read_dealise_4dd(files[0], date, "SBMT"),
          read_dealise_4dd(files[1], date, "SBMT", vel_field='velocity')]
          # read_dealise_region(files[3], vel_field='velocity'),
          # read_dealise_region(files[4]),
          # read_dealise_4dd(files[5], date, "SBMT", vel_field='velocity'),
          # read_dealise_region(files[6]),
          # read_dealise_region(files[7], vel_field='velocity')]

for i in range(len(radars)):
    filename = 'converted_files/' + files[i].split('/')[-1][:-5] + '.uf'
    pyart.io.write_uf(filename, radars[i])
