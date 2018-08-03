#!/usr/bin/env python
from ecmwfapi import ECMWFDataServer

server = ECMWFDataServer()
server.retrieve({
    "class": "ea",
    "dataset": "era5",
    "date": "2017-11-12",
    "expver": "1",
    "levelist": "10/100/250/500/700/850/925/950/975/1000",
    "levtype": "pl",
    "param": "60.128/75.128/76.128/129.128/130.128/131/132/133.128/135.128/138.128/155.128/157.128/203.128/246.128/247.128/248.128",
    "stream": "oper",
    "time": "00:00:00/01:00:00/02:00:00/03:00:00/04:00:00/05:00:00/06:00:00/07:00:00/08:00:00/09:00:00/10:00:00/11:00:00/12:00:00/13:00:00/14:00:00/15:00:00/16:00:00/17:00:00/18:00:00/19:00:00/20:00:00/21:00:00/22:00:00/23:00:00",
    "type": "an",
    "grid": "0.25/0.25",
    "format": "netcdf",
    "target": "era5_20171112.nc"
})
