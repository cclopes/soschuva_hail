"""
ICE WATER MASS GRIDS OF STORM'S LIFECYCLE

Cases:
- 2017-03-14
- 2017-11-15

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import gc
import numpy as np
import pandas as pd
import xarray as xr

import radar_functions as rf


def select_im(
    x_grid,
    below=False,
    above=False,
    between=False,
    zero_height=4,
    forty_height=6,
):
    """
    """

    if below:
        im = (
            x_grid.where((x_grid.z < zero_height * 1e3), drop=True,)
            .MI.sum()
            .values
            * 1e6
        )
    if between:
        im = (
            x_grid.where(
                (
                    (x_grid.z > zero_height * 1e3)
                    & (x_grid.z < forty_height * 1e3)
                ),
                drop=True,
            )
            .MI.sum()
            .values
            * 1e6
        )
    if above:
        im = (
            x_grid.where((x_grid.z > forty_height * 1e3), drop=True,)
            .MI.sum()
            .values
            * 1e6
        )

    return im


def open_select_im(
    filepath_r, xlim_aoi, ylim_aoi, case, zero_height=4, forty_height=6,
):
    """
    """

    # Reading radar + gridding + calculating mass + converting to xarray
    radar = rf.read_radar(filepath_r)
    radar = rf.calculate_radar_mw_mi(radar)
    gradar = rf.grid_radar(
        radar,
        xlim=(-200000.0, 10000.0),
        ylim=(-10000.0, 200000.0),
        fields=["corrected_reflectivity", "MI"],
        grid_shape=(20, 211, 211),
    )
    xgrid = gradar.to_xarray().squeeze()
    del radar, gradar

    # Selecting:
    # - Area of interest
    # - Z >= 40 dBZ
    xgrid = xgrid.where(
        (xgrid.lat > ylim_aoi[0])
        & (xgrid.lat < ylim_aoi[1])
        & (xgrid.lon > xlim_aoi[0])
        & (xgrid.lon < xlim_aoi[1])
        & (xgrid.corrected_reflectivity >= 35)
    )

    # Calculating total mass

    # - BELOW 0°C
    im_b0 = select_im(xgrid, below=True, zero_height=zero_height)

    # - 0°C < T < -40°C
    im_a0 = select_im(
        xgrid, between=True, zero_height=zero_height, forty_height=forty_height,
    )

    # - ABOVE -40°C
    im_a40 = select_im(
        xgrid, above=True, zero_height=zero_height, forty_height=forty_height,
    )

    im = [
        im_b0,
        im_a0,
        im_a40,
    ]
    im_temp = [
        "Below 0°C",
        "0°C > T > -40°C",
        "Above -40°C",
    ]

    ds = pd.DataFrame(
        data={
            "case": case,
            "time": xgrid.time.values.item(),
            "level": im_temp,
            "im": im,
        },
    )

    gc.collect()

    return ds


# Processing for each case

# 2017-03-14

# List of FCTH files
with open("./Radar_Processing/data_files/files_cth_20170314", "r") as file:
    radar_files = list(file.read().split("\n"))
# print(radar_files)

files_date = [pd.to_datetime(i[48:62], utc=True) for i in radar_files]
# print(files_date)

# List of clusters boxes
clusters_box = pd.read_csv(
    "./Radar_Processing/data_files/clusters_20170314.csv", parse_dates=["date"]
)
# print(clusters_box["date"])

# Looping through clusters
i = 0
# total_im = []

cluster_box = clusters_box.iloc[i, :]
tdelta = [abs(cluster_box["date"] - n) for n in files_date]
if min(tdelta) > pd.Timedelta("5 min"):
    total_im = pd.DataFrame(
        {
            "case": "Case 1 2017-03-14",
            "time": cluster_box["date"].tz_convert(None),
            "level": ["Below 0°C", "0°C > T > -40°C", "Above -40°C"],
            "im": np.nan,
        }
    )
    print(cluster_box["date"], "skipped")
else:
    ifile = tdelta.index(min(tdelta))
    total_im = open_select_im(
        filepath_r=radar_files[ifile],
        xlim_aoi=(cluster_box["min_lon"], cluster_box["max_lon"]),
        ylim_aoi=(cluster_box["min_lat"], cluster_box["max_lat"]),
        case="Case 1 2017-03-14",
        zero_height=5.1,
        forty_height=10.6,
    )

for i in range(1, clusters_box.shape[0]):
    cluster_box = clusters_box.iloc[i, :]
    tdelta = [abs(cluster_box["date"] - n) for n in files_date]
    if min(tdelta) > pd.Timedelta("5 min"):
        total_im = pd.concat(
            [
                total_im,
                pd.DataFrame(
                    {
                        "case": "Case 1 2017-03-14",
                        "time": cluster_box["date"].tz_convert(None),
                        "level": [
                            "Below 0°C",
                            "0°C > T > -40°C",
                            "Above -40°C",
                        ],
                        "im": np.nan,
                    }
                ),
            ]
        )
        print(cluster_box["date"], "skipped")
    else:
        ifile = tdelta.index(min(tdelta))
        total_im = pd.concat(
            [
                total_im,
                open_select_im(
                    filepath_r=radar_files[ifile],
                    xlim_aoi=(cluster_box["min_lon"], cluster_box["max_lon"]),
                    ylim_aoi=(cluster_box["min_lat"], cluster_box["max_lat"]),
                    case="Case 1 2017-03-14",
                    zero_height=5.1,
                    forty_height=10.6,
                ),
            ]
        )
        print(cluster_box["date"], "added")
        print(files_date[ifile])
# print(total_im)

total_im.to_csv(
    "./Radar_Processing/data_files/total_im_2017-03-14.csv", na_rep="NA"
)

# 2017-11-15

# List of FCTH files
with open("./Radar_Processing/data_files/files_cth_20171115", "r") as file:
    radar_files = list(file.read().split("\n"))
# print(radar_files)

files_date = [pd.to_datetime(i[48:62], utc=True) for i in radar_files]
# print(files_date)

# List of clusters boxes
clusters_box = pd.read_csv(
    "./Radar_Processing/data_files/clusters_20171115.csv", parse_dates=["date"]
)
# print(clusters_box["date"])

# Looping through clusters
i = 0
# total_im = []

cluster_box = clusters_box.iloc[i, :]
tdelta = [abs(cluster_box["date"] - n) for n in files_date]
if min(tdelta) < pd.Timedelta("5 min"):
    total_im = pd.DataFrame(
        {
            "case": "Case 2 2017-11-15",
            "time": cluster_box["date"].tz_convert(None),
            "level": ["Below 0°C", "0°C > T > -40°C", "Above -40°C"],
            "im": np.nan,
        }
    )
    print(cluster_box["date"], "skipped")
else:
    ifile = tdelta.index(min(tdelta))
    total_im = open_select_im(
        filepath_r=radar_files[ifile],
        xlim_aoi=(cluster_box["min_lon"], cluster_box["max_lon"]),
        ylim_aoi=(cluster_box["min_lat"], cluster_box["max_lat"]),
        case="Case 2 2017-11-15",
        zero_height=4.5,
        forty_height=10.2,
    )
# print(total_im)

for i in range(1, clusters_box.shape[0]):
    cluster_box = clusters_box.iloc[i, :]
    tdelta = [abs(cluster_box["date"] - n) for n in files_date]
    if min(tdelta) > pd.Timedelta("5 min"):
        total_im = pd.concat(
            [
                total_im,
                pd.DataFrame(
                    {
                        "case": "Case 2 2017-11-15",
                        "time": cluster_box["date"].tz_convert(None),
                        "level": [
                            "Below 0°C",
                            "0°C > T > -40°C",
                            "Above -40°C",
                        ],
                        "im": np.nan,
                    }
                ),
            ]
        )
        print(cluster_box["date"], "skipped")
    else:
        ifile = tdelta.index(min(tdelta))
        total_im = pd.concat(
            [
                total_im,
                open_select_im(
                    filepath_r=radar_files[ifile],
                    xlim_aoi=(cluster_box["min_lon"], cluster_box["max_lon"]),
                    ylim_aoi=(cluster_box["min_lat"], cluster_box["max_lat"]),
                    case="Case 2 2017-11-15",
                    zero_height=4.5,
                    forty_height=10.2,
                ),
            ]
        )
        print(cluster_box["date"], "added")
        print(files_date[ifile])
# print(total_im)

total_im.to_csv(
    "./Radar_Processing/data_files/total_im_2017-11-15.csv", na_rep="NA"
)

