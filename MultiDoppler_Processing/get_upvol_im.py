#%%
# -*- coding: utf-8 -*-
"""
UPDRAFT VOLUME FROM MULTIDOP RETRIEVALS

- Specific cases, when hailfall occurred:
    - 2017-11-15 21h40 (SR/FCTH/XPOL)
                 21h50 (SR/FCTH/XPOL)
    - 2017-03-14 18h20 (SR/FCTH)
                 18h30 (SR/FCTH)
                 19h50 (SR/FCTH)
                 20h (SR/FCTH)

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import gc
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import xarray as xr

import radar_functions as rf
import misc_functions as misc
import custom_vars as cv


def select_updraft_vol_im(
    x_grid, below=True, vel=5, zero_height=cv.zerodeg_height
):
    """
    """

    if below:
        u_vol = (
            x_grid.where(
                (x_grid.z < zero_height * 1e3)
                & (x_grid.upward_air_velocity > vel),
                drop=True,
            )
            .upward_air_velocity.count()
            .values
            * 1e9
        )
        im = (
            x_grid.where(
                (x_grid.z < zero_height * 1e3)
                & (x_grid.upward_air_velocity > vel),
                drop=True,
            )
            .MI.sum()
            .values
            * 1e6
        )
        mean_imf = (
            x_grid.where(
                (x_grid.z < zero_height * 1e3)
                & (x_grid.upward_air_velocity > vel),
                drop=True,
            ).MI
            * x_grid.where(
                (x_grid.z < zero_height * 1e3)
                & (x_grid.upward_air_velocity > vel),
                drop=True,
            ).upward_air_velocity
        ).mean().values * 1e-3
        try:
            max_imf = (
                x_grid.where(
                    (x_grid.z < zero_height * 1e3)
                    & (x_grid.upward_air_velocity > vel),
                    drop=True,
                ).MI
                * x_grid.where(
                    (x_grid.z < zero_height * 1e3)
                    & (x_grid.upward_air_velocity > vel),
                    drop=True,
                ).upward_air_velocity
            ).max().values * 1e-3
        except ValueError:
            max_imf = np.nan
    else:
        u_vol = (
            x_grid.where(
                (x_grid.z > zero_height * 1e3)
                & (x_grid.upward_air_velocity > vel),
                drop=True,
            )
            .upward_air_velocity.count()
            .values
            * 1e9
        )
        im = (
            x_grid.where(
                (x_grid.z > zero_height * 1e3)
                & (x_grid.upward_air_velocity > vel),
                drop=True,
            )
            .MI.sum()
            .values
            * 1e6
        )
        mean_imf = (
            x_grid.where(
                (x_grid.z > zero_height * 1e3)
                & (x_grid.upward_air_velocity > vel),
                drop=True,
            ).MI
            * x_grid.where(
                (x_grid.z > zero_height * 1e3)
                & (x_grid.upward_air_velocity > vel),
                drop=True,
            ).upward_air_velocity
        ).mean().values * 1e-3
        try:
            max_imf = (
                x_grid.where(
                    (x_grid.z > zero_height * 1e3)
                    & (x_grid.upward_air_velocity > vel),
                    drop=True,
                ).MI
                * x_grid.where(
                    (x_grid.z > zero_height * 1e3)
                    & (x_grid.upward_air_velocity > vel),
                    drop=True,
                ).upward_air_velocity
            ).max().values * 1e-3
        except ValueError:
            max_imf = np.nan

    if u_vol == 0:
        return (np.nan, im, mean_imf, max_imf)
    else:
        return (u_vol, im, mean_imf, max_imf)


def open_select_upvol_im(
    filepath_m,
    filepath_r,
    sounding,
    xlim_aoi,
    ylim_aoi,
    case,
    zero_height=cv.zerodeg_height,
):
    """
    """

    # Reading merged radar + converting to xarray
    grid = misc.open_object(filepath_m)
    xgrid = grid.to_xarray().squeeze()
    del grid

    # Reading radar + gridding + calculating mass + converting to xarray
    radar = rf.read_radar(filepath_r)
    radar = rf.calculate_radar_hid(radar, sounding)
    gradar = rf.grid_radar(
        radar,
        xlim=cv.grid_xlim,
        ylim=cv.grid_ylim,
        fields=["MI"],
        grid_shape=cv.grid_shape,
    )
    xgradar = gradar.to_xarray().squeeze()
    del radar, gradar

    # Merging files
    xgrid = xgrid.assign({"MI": xgradar.MI})
    xgrid = xgrid.swap_dims({"x": "lon", "y": "lat"})
    del xgradar

    # Selecting:
    # - Area of interest
    # - Z >= 40 dBZ
    xgrid = xgrid.where(
        (xgrid.lat > ylim_aoi[0])
        & (xgrid.lat < ylim_aoi[1])
        & (xgrid.lon > xlim_aoi[0])
        & (xgrid.lon < xlim_aoi[1])
        & (xgrid.reflectivity >= 40)
    )

    # Calculating updraft volume + total mass
    # - below 0°C
    # -- w > 0 m/s
    uvol_b0_a0, im_b0_a0, meanimf_b0_a0, maximf_b0_a0 = select_updraft_vol_im(
        xgrid, vel=0, zero_height=zero_height
    )
    # -- w > 5 m/s
    uvol_b0_a5, im_b0_a5, meanimf_b0_a5, maximf_b0_a5 = select_updraft_vol_im(
        xgrid, vel=5, zero_height=zero_height
    )
    # -- w > 10 m/s
    (
        uvol_b0_a10,
        im_b0_a10,
        meanimf_b0_a10,
        maximf_b0_a10,
    ) = select_updraft_vol_im(xgrid, vel=10, zero_height=zero_height)
    # -- w > 15 m/s
    (
        uvol_b0_a15,
        im_b0_a15,
        meanimf_b0_a15,
        maximf_b0_a15,
    ) = select_updraft_vol_im(xgrid, vel=15, zero_height=zero_height)
    # -- w > 205 m/s
    (
        uvol_b0_a20,
        im_b0_a20,
        meanimf_b0_a20,
        maximf_b0_a20,
    ) = select_updraft_vol_im(xgrid, vel=20, zero_height=zero_height)
    # - above 0°C
    # -- w > 0 m/s
    uvol_a0_a0, im_a0_a0, meanimf_a0_a0, maximf_a0_a0 = select_updraft_vol_im(
        xgrid, below=False, vel=0, zero_height=zero_height
    )
    # -- w > 5 m/s
    uvol_a0_a5, im_a0_a5, meanimf_a0_a5, maximf_a0_a5 = select_updraft_vol_im(
        xgrid, below=False, vel=5, zero_height=zero_height
    )
    # -- w > 10 m/s
    (
        uvol_a0_a10,
        im_a0_a10,
        meanimf_a0_a10,
        maximf_a0_a10,
    ) = select_updraft_vol_im(
        xgrid, below=False, vel=10, zero_height=zero_height
    )
    # -- w > 15 m/s
    (
        uvol_a0_a15,
        im_a0_a15,
        meanimf_a0_a15,
        maximf_a0_a15,
    ) = select_updraft_vol_im(
        xgrid, below=False, vel=15, zero_height=zero_height
    )
    # -- w > 20 m/s
    (
        uvol_a0_a20,
        im_a0_a20,
        meanimf_a0_a20,
        maximf_a0_a20,
    ) = select_updraft_vol_im(
        xgrid, below=False, vel=20, zero_height=zero_height
    )

    uvol = [
        uvol_b0_a0,
        uvol_b0_a5,
        uvol_b0_a10,
        uvol_b0_a15,
        uvol_b0_a20,
        uvol_a0_a0,
        uvol_a0_a5,
        uvol_a0_a10,
        uvol_a0_a15,
        uvol_a0_a20,
    ]
    im = [
        im_b0_a0,
        im_b0_a5,
        im_b0_a10,
        im_b0_a15,
        im_b0_a20,
        im_a0_a0,
        im_a0_a5,
        im_a0_a10,
        im_a0_a15,
        im_a0_a20,
    ]
    mean_imf = [
        meanimf_b0_a0,
        meanimf_b0_a5,
        meanimf_b0_a10,
        meanimf_b0_a15,
        meanimf_b0_a20,
        meanimf_a0_a0,
        meanimf_a0_a5,
        meanimf_a0_a10,
        meanimf_a0_a15,
        meanimf_a0_a20,
    ]
    max_imf = [
        maximf_b0_a0,
        maximf_b0_a5,
        maximf_b0_a10,
        maximf_b0_a15,
        maximf_b0_a20,
        maximf_a0_a0,
        maximf_a0_a5,
        maximf_a0_a10,
        maximf_a0_a15,
        maximf_a0_a20,
    ]
    uvol_temp = [
        "Below 0°C",
        "Below 0°C",
        "Below 0°C",
        "Below 0°C",
        "Below 0°C",
        "Above 0°C",
        "Above 0°C",
        "Above 0°C",
        "Above 0°C",
        "Above 0°C",
    ]
    uvol_vel = [
        "Above 0 m/s",
        "Above 5 m/s",
        "Above 10 m/s",
        "Above 15 m/s",
        "Above 20 m/s",
        "Above 0 m/s",
        "Above 5 m/s",
        "Above 10 m/s",
        "Above 15 m/s",
        "Above 20 m/s",
    ]

    ds = pd.DataFrame(
        data={
            "case": case,
            "time": xgrid.time.values.item(),
            "level": uvol_temp,
            "vel": uvol_vel,
            "uvol": uvol,
            "im": im,
            "mean_imf": mean_imf,
            "max_imf": max_imf,
        },
    )

    gc.collect()

    return ds


# Joining cases
uvol_im = pd.concat(
    [
        open_select_upvol_im(
            filepath_m="./MultiDoppler_Processing/cases/2017-03-14_18h20/sr-fcth_cf.pkl",
            filepath_r="./Data/RADAR/CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314181729.HDF5",
            sounding="./Data/SOUNDINGS/83779_2017031412Z.txt",
            xlim_aoi=(-47.2, -47),
            ylim_aoi=(-22.73, -22.6),
            case="Case 1 2017-03-14\nCosmópolis",
        ),
        open_select_upvol_im(
            filepath_m="./MultiDoppler_Processing/cases/2017-03-14_18h30/sr-fcth_cf.pkl",
            filepath_r="./Data/RADAR/CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314182730.HDF5",
            sounding="./Data/SOUNDINGS/83779_2017031412Z.txt",
            xlim_aoi=(-47.2, -47),
            ylim_aoi=(-22.76, -22.61),
            case="Case 1 2017-03-14\nCosmópolis",
        ),
        open_select_upvol_im(
            filepath_m="./MultiDoppler_Processing/cases/2017-03-14_19h50/sr-fcth_cf.pkl",
            filepath_r="./Data/RADAR/CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314194729.HDF5",
            sounding="./Data/SOUNDINGS/83779_2017031412Z.txt",
            xlim_aoi=(-47.3, -47.1),
            ylim_aoi=(-23.1, -22.95),
            case="Case 1 2017-03-14\nIndaiatuba",
        ),
        open_select_upvol_im(
            filepath_m="./MultiDoppler_Processing/cases/2017-03-14_20h00/sr-fcth_cf.pkl",
            filepath_r="./Data/RADAR/CTH/level_0_hdf5/2017-03-14/PNOVA2-20170314195729.HDF5",
            sounding="./Data/SOUNDINGS/83779_2017031412Z.txt",
            xlim_aoi=(-47.25, -47.1),
            ylim_aoi=(-23.11, -22.95),
            case="Case 1 2017-03-14\nIndaiatuba",
        ),
        open_select_upvol_im(
            filepath_m="./MultiDoppler_Processing/cases/2017-11-15_21h40/sr-fcth-xpol_cf.pkl",
            filepath_r="./Data/RADAR/CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115214004.HDF5",
            sounding="./Data/SOUNDINGS/83779_2017111512Z.txt",
            xlim_aoi=(-47.31, -47.19),
            ylim_aoi=(-23.07, -22.9),
            case="Case 2 2017-11-15\nIndaiatuba",
            zero_height=4.5,
        ),
        open_select_upvol_im(
            filepath_m="./MultiDoppler_Processing/cases/2017-11-15_21h50/sr-fcth-xpol_cf.pkl",
            filepath_r="./Data/RADAR/CTH/level_0_hdf5/2017-11-15/PNOVA2-20171115215004.HDF5",
            sounding="./Data/SOUNDINGS/83779_2017111512Z.txt",
            xlim_aoi=(-47.3, -47.15),
            ylim_aoi=(-23.1, -22.97),
            case="Case 2 2017-11-15\nIndaiatuba",
            zero_height=4.5,
        ),
    ],
)

print(uvol_im)

uvol_im.to_csv(
    "./MultiDoppler_Processing/multidop_out/updraft_vol_im_all_cases.csv"
)

# # Testing
# grid_2rad = misc.open_object(
#     "MultiDoppler_Processing/cases/2017-11-15_21h50/sr-fcth-xpol_cf.pkl"
# )
# print(grid_2rad.fields.keys())

# Converting to xarray
# xgrid_2rad = grid_2rad.to_xarray().squeeze()
# xgrid_2rad = xgrid_2rad.swap_dims({"x": "lon", "y": "lat"})
# print(xgrid_2rad.upward_air_velocity)

# # Selecting:
# # - Area of interest
# # - Z >= 40 dBZ
# xlim_aoi, ylim_aoi = (-47.3, -47.15), (-23.1, -22.97)
# xgrid_2rad = xgrid_2rad.where(
#     (xgrid_2rad.lat > ylim_aoi[0])
#     & (xgrid_2rad.lat < ylim_aoi[1])
#     & (xgrid_2rad.lon > xlim_aoi[0])
#     & (xgrid_2rad.lon < xlim_aoi[1])
#     & (xgrid_2rad.reflectivity >= 40)
# )

# # Quick plot to test
# xgrid_2rad.reflectivity.sel(z=3 * 1e3, method="nearest").plot.pcolormesh()
# plt.plot(-47.20541, -23.02940, 'kx')
# plt.grid()
# plt.xlim((-47.75, -46.25))
# plt.ylim((-23.5, -22))
# plt.savefig("/mnt/c/Users/ccl/Downloads/ccel_2017-11-15_21h50.png", dpi=300)


# %%
