import radar_functions as rf
import custom_vars as cv
import pyart
import matplotlib.pyplot as plt

radar = pyart.io.read_uf(cv.filename)
#radar = rf.read_radar(cv.filename)
print(radar.fields['cross_correlation_ratio'])

display = pyart.graph.RadarDisplay(radar)
fig = plt.figure()
display.plot('cross_correlation_ratio', 0)
plt.show()
