#!/usr/bin/env python
# -*- coding: utf-8 -*-

from netCDF4 import Dataset
import numpy as np
import argparse
import time as t
import matplotlib.pyplot as plt
import matplotlib.image as image
import os
from osgeo import osr
from osgeo import gdal
from mpl_toolkits.basemap import Basemap
from shutil import copyfile

###############################################################################
## Ploter for All variables
def gen_map_plot(right_c, left_c, file_name, data, im_path, date, col_map):
    """
    Efectivile creates the plot,
    """
    try:
        startm = t.time()
        im = image.imread(im_path)
        im = im[::4,::4]
        fig1 = plt.figure(file_name,figsize=(9.1, 7.8), frameon=False)
        map1 = Basemap(llcrnrlat=float(left_c[0]), urcrnrlat=float(right_c[0]),\
                         llcrnrlon=float(left_c[1]), urcrnrlon=float(right_c[1]), resolution='h', epsg=4326)
        map1.drawcoastlines(color='y', linewidth=0.45)
        map1.drawcountries(linewidth=0.45, linestyle='solid', color='y', antialiased=1, ax=None, zorder=None)
        map1.drawstates(linewidth=0.4, linestyle='solid', color='y', antialiased=1, ax=None, zorder=None)
        map1.imshow(data[:,:], cmap=col_map, origin='upper') #plot the data
        map1.colorbar(location='bottom', size='5%', pad='2%') #genarates color bar
        ### Remove this line to ommit the logo
        fig1.figimage(im, 65, 2020, zorder=1, origin='upper', alpha=0.95) #embed logo
        ###
        fig1.tight_layout()
        plt.annotate('GOES16_'+ var + ' ' + date , xy=(0.005, 0.015), xycoords='axes fraction', color='y')#embed date 
        plt.savefig(file_name, dpi=300, pad_inches=0,facecolor=None, edgecolor=None,frameon=None)#saves figure
        print ('End of plot, time:', t.time() - startm, 'seconds')

        return True
    except:
        return False
###############################################################################
## Ploter for True_COlor
def gen_true_plot(right_c, left_c, file_name, data, im_path, date):
    """
    Efectivile creates the plot,
    """
    try:
        startm = t.time()
        im = image.imread(im_path)
        im = im[::4,::4]
        fig1 = plt.figure(file_name,figsize=(9.1, 7.8), frameon=False)
        map1 = Basemap(llcrnrlat=float(left_c[0]), urcrnrlat=float(right_c[0]),\
                         llcrnrlon=float(left_c[1]), urcrnrlon=float(right_c[1]), resolution='h', epsg=4326)
        map1.drawcoastlines(color='y', linewidth=0.45)
        map1.drawcountries(linewidth=0.45, linestyle='solid', color='y', antialiased=1, ax=None, zorder=None)
        map1.drawstates(linewidth=0.4, linestyle='solid', color='y', antialiased=1, ax=None, zorder=None)
        map1.imshow(data[:,:], origin='upper') #plot the data
        ### Remove this line to ommit the logo
        fig1.figimage(im, 65, 1820, zorder=1, origin='upper', alpha=0.95) #embed logo
        ### 
        fig1.tight_layout()
        plt.annotate('GOES16 ' + date + 'Pseudo True Color', xy=(0.005, 0.015), xycoords='axes fraction', color='y')#embed date 
        plt.savefig(file_name, dpi=300, pad_inches=0,facecolor=None, edgecolor=None,frameon=None)#saves figure
        print ('End of plot true_color, time:', t.time() - startm, 'seconds')

        return True
    except:
        return False
###############################################################################
## GDAL Remap
def getGeoT(extent, nlines, ncols):
    '''
    Calculate necessary paramaters for GDAL library
    '''
    # Compute resolution based on data dimension
    resx = (extent[2] - extent[0]) / ncols
    resy = (extent[3] - extent[1]) / nlines
    return [extent[0], resx, 0, extent[3] , 0, -resy]

def remap_grid(data, path, var_name, extent, resolution=2):
    '''
    Change the projection of GOES16 nc files from 'geos' to 'longlat'(pseudomercator)
    All constants came form NOOA datasheet for GOES16
    '''
    KM_PER_DEGREE = 111.32
    # GOES-16 Extention (satellite projection, position of corners) [llx, lly, urx, ury]
    GOES16_EXTENT = [-5434894.885056, -5434894.885056, 5434894.885056, 5434894.885056]
    
    # GOES-16 Spatial reference system and adjustments 
    sourcePrj = osr.SpatialReference()
    sourcePrj.ImportFromProj4('+proj=geos +h=35786023.0 +a=6378137.0 +b=6356752.31414 +f=0.00335281068119356027 +lat_0=0.0 +lon_0=-75 +sweep=x +no_defs')
    
    # Lat/lon WSG84 Spatial reference system(projection, elipsoid and geoid)
    targetPrj = osr.SpatialReference()
    targetPrj.ImportFromProj4('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs') #change here for other projections

    if not gdal.GetDriverByName('HDF5'):
        raise Exception('HDF5 library is not available')

    connectionInfo = 'HDF5:\"'+ path.split('.')[0] + 'h5' + '\"://' + var_name
    raw = gdal.Open(connectionInfo, gdal.GA_ReadOnly)
    raw.SetProjection(sourcePrj.ExportToWkt())
    raw.SetGeoTransform(getGeoT(GOES16_EXTENT, raw.RasterYSize, raw.RasterXSize))

    sizex = int(((extent[2] - extent[0]) * KM_PER_DEGREE)/resolution)
    sizey = int(((extent[3] - extent[1]) * KM_PER_DEGREE)/resolution)

    memDriver = gdal.GetDriverByName('MEM')
    grid = memDriver.Create('grid', sizex, sizey, 1, gdal.GDT_Float32)
    grid.SetProjection(targetPrj.ExportToWkt())
    grid.SetGeoTransform(getGeoT(extent, grid.RasterYSize, grid.RasterXSize))
    start = t.time()

    gdal.ReprojectImage(raw, grid, sourcePrj.ExportToWkt(), targetPrj.ExportToWkt(), gdal.GRA_NearestNeighbour) 
    print ('End of reprojection, time:', t.time() - start, 'seconds')
    array = grid.ReadAsArray()
    np.ma.masked_where(array, array == -1, False)
    grid.GetRasterBand(1).SetNoDataValue(-1)

    grid.GetRasterBand(1).WriteArray(array)
    out = grid.ReadAsArray()
    del grid, raw
    return out

###############################################################################
## Colorbar selector
def get_color_map(var):
    '''
    You have to specify colorbars you want, or it will default to 
    matplolib Greys color bar. 
    '''
    return{
           'CMI_C13' : 'Greys',
           'CMI_C01' : 'Greys_r',
           'CMI_C02' : 'Greys_r',
          }.get(var, 'Greys')
###############################################################################
## Arg parser and help
parser = argparse.ArgumentParser(description="This script genarete plots from NetCDF4")
parser.add_argument('-i', help="Imput NetCDF4 file", action='store'\
                                       ,required=True, dest='nc_path')
### To remove logo comment/remove lines 149, 63, 35. 
### Also edit arguments gen_map_plot and gen_true_plot removing im_path
### lines 224, 237, 47, 18
parser.add_argument('-w', help="Watermark PNG file", action='store',\
                                        required=True, dest='im_path')
parser.add_argument('-o', help="Output path(default=.", action='store',\
                                      required=False, dest='out_path')
parser.add_argument('-v', help="Variables list(default=all variables)", action='store',\
                             required=False, dest='nc_vars', type=str)
parser.add_argument('-r', help="Resolution(1=hightest, 10=lowest, default=4)",\
                     action='store',required=False, dest='resolution')
parser.add_argument('-l', help="Lat0, Lon0, Lat1, Lon2",\
              action='store',required=False, dest='lat_lon', type=str)
parser.add_argument('-tc', help="True Colors(True or False, default=True)",\
                     action='store',required=False, dest='tru_col')

args=parser.parse_args()
nc_path = args.nc_path
im_path = args.im_path
try:
    nc_vars = [str(item) for item in args.nc_vars.split(',')] 
except:
    nc_vars = ['CMI_C01','CMI_C02', 'CMI_C03','CMI_C04','CMI_C05', 'CMI_C06','CMI_C07',
                'CMI_C08','CMI_C09','CMI_C10','CMI_C11','CMI_C12','CMI_C13','CMI_C14',
                'CMI_C15','CMI_C16'] 
out_path = args.out_path  or './'
try:
    resolution = int(args.resolution)
except:
    resolution = 4
try:
        lat_lon = [float(item) for item in args.lat_lon.split(',')]
        left_c  = [lat_lon[0], lat_lon[1]]
        right_c = [lat_lon[2], lat_lon[3]]
        extent = [lat_lon[1], lat_lon[0], lat_lon[3], lat_lon[2]]
except:
        left_c  = [-89.9, -179.0]
        right_c = [89.9, -1]
        extent = [-175.0, -80.0, -5.0, 80.0]
###############################################################################
## Execution
nc_file =  Dataset(nc_path, 'r')
copyfile(nc_path, nc_path.split('.')[0]+'h5') #necessary to avoid crash on GDAL library
date = nc_file.date_created 

###True_Color
if args.tru_col != 'False':
    '''
    Pseudo true color uses vegetation chanel(CMI_C03) to estimate green chanel
    All constants came from http://edc.occ-data.org/goes16/python example
    '''
    nc_red = nc_file.variables['CMI_C02']
    nc_blu = nc_file.variables['CMI_C01']
    nc_veg = nc_file.variables['CMI_C03']
    
    red = remap_grid(nc_red, nc_path, 'CMI_C02', extent, 4)
    red = (red * np.pi * 0.3)/663.274497
    red = np.maximum(red, 0.0)
    red = np.minimum(red, 0.95)
    red = np.sqrt(red)
    
    blu = remap_grid(nc_blu, nc_path, 'CMI_C01', extent, 4)
    blu = (blu * np.pi * 0.3)/726.721072
    blu = np.maximum(blu, 0.0)
    blu = np.minimum(blu, 0.95)
    blu = np.sqrt(blu)
    
    veg = remap_grid(nc_veg, nc_path, 'CMI_C03', extent, 4)
    veg = (veg * np.pi * 0.3)/441.868715
    veg = np.maximum(veg, 0.0)
    veg = np.minimum(veg, 0.95)
    veg = np.sqrt(veg)
    
    gre = 0.4835818*red + 0.4570694*blu + 0.06038137*veg
    
    rgb = np.stack([red, gre, blu], axis=2)  
    
    true_file_name = out_path + 'true_color_'  + date +'.png'
    suc = gen_true_plot(right_c, left_c, true_file_name, rgb, im_path, date)
    if suc == True:
        print('True_Color Done!')
    else:
        print('Error ploting True_Color')

###All vars
for var in nc_vars:
    col_map = get_color_map(var)
    data = nc_file.variables[var]

    data = remap_grid(data, nc_path, var, extent, resolution)
    file_name = out_path + var + '_' + date + '.png'
    suc = gen_map_plot(right_c, left_c, file_name, data, im_path, date, col_map)
    if suc == True:
            s = 'plot %s, done!' %(var)
            print(s)
    else:
            s = 'Fail to plot %s' %(var)
            print(s)

nc_file.close() 
os.remove(nc_path.split('.')[0]+'h5')
os.remove(nc_path.split('.')[0]+'h5.aux.xml')
exit()