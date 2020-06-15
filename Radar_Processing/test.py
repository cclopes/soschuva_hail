import radar_functions as rf
import custom_vars as cv
import pyart
import matplotlib.pyplot as plt


radar = rf.read_radar("Data/RADAR/SR/level_0/2017-03-14/SRO-250--2017-03-14--18-20-23.mvol")
# radar = pyart.io.read_uf("Data/RADAR/CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314195729.HDF5")
#radar = rf.read_radar(cv.filename)
print(radar.info())

# display = pyart.graph.RadarDisplay(radar)
# fig = plt.figure()
# display.plot('cross_correlation_ratio', 0)
# plt.show()
