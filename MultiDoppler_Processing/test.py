from read_brazil_radar_py3 import read_rainbow_hdf5
import h5py

radar = read_rainbow_hdf5("../Data/RADAR/CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115214004.HDF5")
print(radar.fields.keys())

#radar = h5py.File("../Data/RADAR/CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115214004.HDF5")
#print((str(radar['scan0']['how'].attrs['timestamp'][0])[2:-1]))

#print(type('%Y-%m-%dT%H:%M:%S.000Z'))
