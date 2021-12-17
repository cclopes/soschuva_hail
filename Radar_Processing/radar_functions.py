# -*- coding: utf-8 -*-
"""
GENERAL FUNCTIONS TO DEAL WITH RADAR DATA

@author: Camila Lopes (camila.lopes@iag.usp.br)
"""

import time
from copy import deepcopy

import numpy as np
import numpy.ma as ma
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from matplotlib.colors import LinearSegmentedColormap, BoundaryNorm
from matplotlib.cm import revcmap
from mpl_toolkits.basemap import cm
import cartopy.crs as ccrs
from cartopy.io.shapereader import Reader

import pyart

try:
    import multidop
except ModuleNotFoundError:
    pass
try:
    from SkewTplus.sounding import sounding
except ModuleNotFoundError:
    pass
from csu_radartools import csu_fhc, csu_liquid_ice_mass


from cpt_convert import loadCPT
from read_brazil_radar_py3 import read_rainbow_hdf5
from misc_functions import check_sounding_for_montonic


def read_radar(filename):
    """
    Open radar file with pyart or derived functions

    Parameters
    ----------
    filename: .mvol or .HDF5 file

    Returns
    -------
    radar: Py-ART radar data
    """

    try:
        # .mvol files
        radar = pyart.aux_io.read_gamic(filename)
    except (AttributeError, TypeError):
        # .HDF5 files
        radar = read_rainbow_hdf5(filename)
    return radar


def calculate_radar_hid(radar, sounding_names, radar_band="S"):
    """
    Use radar and sounding data to calculate:
    - Temperature and height profiles
    - Hydrometeor classification with CSU_RadarTools
    - Liquid and ice water masses, ice fraction

    Parameters
    ----------
    radar: Py-ART radar data
    sounding_names: list of sounding data filenames
    radar_band: radar band

    Returns
    -------
    file: radar data with HID and water masses
    """

    # Getting date for sounding - optional
    # radar_date = pd.to_datetime(radar.time['units'][14:])

    # Interpolating with sounding
    soundings = sounding(sounding_names)
    # - optional: sounding_names.loc[str(radar_date.date())].item()
    radar_T, radar_z = interpolate_sounding_to_radar(soundings, radar)

    # Extracting necessary variables
    z_corrected = radar.fields["corrected_reflectivity"]["data"]
    zdr = radar.fields["differential_reflectivity"]["data"]
    kdp = radar.fields["specific_differential_phase"]["data"]
    rho_hv = radar.fields["cross_correlation_ratio"]["data"]

    # Classifying
    scores = csu_fhc.csu_fhc_summer(
        weights={"DZ": 1, "DR": 1, "KD": 1, "RH": 1, "LD": 1, "T": 1},
        dz=z_corrected,
        zdr=zdr,
        kdp=kdp,
        rho=rho_hv,
        use_temp=True,
        T=radar_T,
        band=radar_band,
        verbose=True,
        method="hybrid",
    )
    fh = np.argmax(scores, axis=0) + 1
    # - Adding to radar file
    radar = add_field_to_radar_object(fh, radar, standard_name="Hydrometeor ID")

    # - Calculating liquid and ice mass
    mw, mi = csu_liquid_ice_mass.calc_liquid_ice_mass(
        z_corrected, zdr, radar_z / 1000.0, T=radar_T
    )

    # - Adding to radar file
    file = add_field_to_radar_object(
        mw,
        radar,
        field_name="MW",
        units=r"$g\  m^{-3}$",
        long_name="Liquid Water Mass",
        standard_name="Liquid Water Mass",
    )
    file = add_field_to_radar_object(
        mi,
        file,
        field_name="MI",
        units=r"$g\  m^{-3}$",
        long_name="Ice Water Mass",
        standard_name="Ice Water Mass",
    )

    return file


def calculate_radar_mw_mi(radar, radar_band="S"):
    """
    Use radar data to calculate:
    - Liquid and ice water masses, ice fraction

    Parameters
    ----------
    radar: Py-ART radar data
    radar_band: radar band

    Returns
    -------
    file: radar data with HID and water masses
    """

    # - optional: sounding_names.loc[str(radar_date.date())].item()
    radar_z = get_z_from_radar(radar)

    # Extracting necessary variables
    z_corrected = radar.fields["corrected_reflectivity"]["data"]
    zdr = radar.fields["differential_reflectivity"]["data"]

    # - Calculating liquid and ice mass
    mw, mi = csu_liquid_ice_mass.calc_liquid_ice_mass(
        z_corrected, zdr, radar_z / 1000.0,
    )

    # - Adding to radar file
    file = add_field_to_radar_object(
        mw,
        radar,
        field_name="MW",
        units=r"$g\  m^{-3}$",
        long_name="Liquid Water Mass",
        standard_name="Liquid Water Mass",
    )
    file = add_field_to_radar_object(
        mi,
        file,
        field_name="MI",
        units=r"$g\  m^{-3}$",
        long_name="Ice Water Mass",
        standard_name="Ice Water Mass",
    )

    return file


def radar_coords_to_cart(rng, az, ele, debug=False):
    """
    TJL - taken from old Py-ART version
    Calculate Cartesian coordinate from radar coordinates

    Parameters
    ----------
    rng : array
        Distances to the center of the radar gates (bins) in kilometers.
    az : array
        Azimuth angle of the radar in degrees.
    ele : array
        Elevation angle of the radar in degrees.

    Returns
    -------
    x, y, z : array
        Cartesian coordinates in meters from the radar.

    Notes
    -----
    The calculation for Cartesian coordinate is adapted from equations
    2.28(b) and 2.28(c) of Doviak and Zrnic [1]_ assuming a
    standard atmosphere (4/3 Earth's radius model).
    .. math::
        z = \\sqrt{r^2+R^2+r*R*sin(\\theta_e)} - R
        s = R * arcsin(\\frac{r*cos(\\theta_e)}{R+z})
        x = s * sin(\\theta_a)
        y = s * cos(\\theta_a)
    Where r is the distance from the radar to the center of the gate,
    :math:\\theta_a is the azimuth angle, :math:\\theta_e is the
    elevation angle, s is the arc length, and R is the effective radius
    of the earth, taken to be 4/3 the mean radius of earth (6371 km).

    References
    ----------
    .. [1] Doviak and Zrnic, Doppler Radar and Weather Observations, Second
        Edition, 1993, p. 21.
    """
    theta_e = ele * np.pi / 180.0  # elevation angle in radians
    theta_a = az * np.pi / 180.0  # azimuth angle in radians
    R = 6371.0 * 1000.0 * 4.0 / 3.0  # effective radius of earth in meters
    r = rng * 1000.0  # distances to gates in meters

    z = (r ** 2 + R ** 2 + 2.0 * r * R * np.sin(theta_e)) ** 0.5 - R
    s = R * np.arcsin(r * np.cos(theta_e) / (R + z))  # arc length in m
    x = s * np.sin(theta_a)
    y = s * np.cos(theta_a)
    return x, y, z


def get_z_from_radar(radar):
    """
    Calculates radar height correspondent to elevations.

    Parameters
    ----------
    radar: Py-ART radar data

    Returns
    -------
    Height in radar coordinates
    """
    azimuth_1D = radar.azimuth["data"]
    elevation_1D = radar.elevation["data"]
    srange_1D = radar.range["data"]
    sr_2d, az_2d = np.meshgrid(srange_1D, azimuth_1D)
    el_2d = np.meshgrid(srange_1D, elevation_1D)[1]
    xx, yy, zz = radar_coords_to_cart(sr_2d / 1000.0, az_2d, el_2d)
    return zz + radar.altitude["data"]


def interpolate_sounding_to_radar(sounding, radar):
    """
    Interpolate sounding data to radar

    Parameters
    ----------
    sounding: sounding read by SkewT
    radar: Py-ART radar data

    Returns
    -------
    rad_T1d: temperature in radar coordinates
    radar_z: height in radar coordinates
    """

    radar_z = get_z_from_radar(radar)
    radar_T = None
    snd_T, snd_z = check_sounding_for_montonic(sounding)
    shape = np.shape(radar_z)
    rad_z1d = radar_z.ravel()
    rad_T1d = np.interp(rad_z1d, snd_z, snd_T)
    return np.reshape(rad_T1d, shape), radar_z


def add_field_to_radar_object(
    field,
    radar,
    field_name="FH",
    units="unitless",
    long_name="Hydrometeor ID",
    standard_name="Hydrometeor ID",
    dz_field="corrected_reflectivity",
):
    """
    Adds a newly created field to the Py-ART radar object. If reflectivity is a
    masked array, make the new field masked the same as reflectivity.

    Parameters
    ----------
    field: Py-ART field
    radar: Py-ART radar object
    field_name: name of the field to be added
    units: units of the field to be added
    long_name: long name of the field to be added
    standard_name: standard name of the field to be added
    dz_field: field to be based on

    Returns
    -------
    radar: Py-ART radar data with added field
    """
    fill_value = -32768
    masked_field = np.ma.asanyarray(field)
    masked_field.mask = masked_field == fill_value
    if hasattr(radar.fields[dz_field]["data"], "mask"):
        setattr(
            masked_field,
            "mask",
            np.logical_or(
                masked_field.mask, radar.fields[dz_field]["data"].mask
            ),
        )
        fill_value = radar.fields[dz_field]["data"].fill_value
    field_dict = {
        "data": masked_field,
        "units": units,
        "long_name": long_name,
        "standard_name": standard_name,
        "fill_value": fill_value,
    }
    radar.add_field(field_name, field_dict, replace_existing=True)
    return radar


def add_field_to_grid_object(
    field,
    grid,
    field_name="Reflectivity",
    units="dBZ",
    long_name="Reflectivity",
    standard_name="Reflectivity",
    dz_field="reflectivity",
):
    """
    Adds a newly created field to the Py-ART grid object. If reflectivity is a
    masked array, make the new field masked the same as reflectivity.

    Parameters
    ----------
    field: Py-ART field
    grid: Py-ART grid object
    field_name: name of the field to be added
    units: units of the field to be added
    long_name: long name of the field to be added
    standard_name: standard name of the field to be added
    dz_field: field to be based on

    Returns
    -------
    grid: Py-ART gridded data with added field
    """

    fill_value = -32768
    masked_field = np.ma.asanyarray(field)
    masked_field.mask = masked_field == fill_value
    if hasattr(grid.fields[dz_field]["data"], "mask"):
        setattr(
            masked_field,
            "mask",
            np.logical_or(
                masked_field.mask, grid.fields[dz_field]["data"].mask
            ),
        )
        fill_value = grid.fields[dz_field]["_FillValue"]
    field_dict = {
        "data": masked_field,
        "units": units,
        "long_name": long_name,
        "standard_name": standard_name,
        "_FillValue": fill_value,
    }
    grid.add_field(field_name, field_dict, replace_existing=True)

    return grid


def grid_radar(
    radar,
    grid_shape=(20, 301, 301),
    xlim=(-150000, 150000),
    ylim=(-150000, 150000),
    zlim=(1000, 20000),
    fields=["reflectivity", "velocity"],
    origin=None,
    for_multidop=False,
):

    """
    Using radar data:
    - Create a gridded version (grid) with pyart
    - (If for_multidop=True) add azimuth and elevation information as fields of
        grid using multidop

    Parameters
    ----------
    radar: Py-ART radar data
    grid_shape: grid shape specifications
        (# points in z, # points in y, # points in x)
    xlim, ylim, zlim: plot limits in x, y, z
        (min, max) in meters
    fields: name of the reflectivity and velocity fields
    origin: custom grid origin
    for_multidop: True if gridded for multidop

    Returns
    -------
    grid: gridded radar data
    """

    # Count the time
    bt = time.time()

    # Fixing linearity
    # copy = deepcopy(radar.fields[fields[0]]['data'])
    # linear_field = ma.power(10.0, (copy/10.0))
    # radar.add_field_like(fields[0], fields[0], linear_field,
    #                      replace_existing=True)
    # try:
    #     radar.fields[fields[0]]['missing_value'] = [
    #         1.0 * radar.fields[fields[0]]['_FillValue']]
    # except KeyError:
    #     radar.fields[fields[0]]['_FillValue'] = (
    #         radar.fields[fields[0]]['data'].fill_value)
    #     radar.fields[fields[0]]['missing_value'] = [
    #         1.0 * radar.fields[fields[0]]['_FillValue']]
    # fields.append(fields[0])

    if not for_multidop:
        gatefilter = pyart.filters.GateFilter(radar)
        # gatefilter.exclude_below(fields[4], 0.8)
    else:
        gatefilter = None

    radar_list = [radar]

    if origin is None:
        origin = (radar.latitude["data"][0], radar.longitude["data"][0])

    grid = pyart.map.grid_from_radars(
        radar_list,
        gatefilters=gatefilter,
        grid_shape=grid_shape,
        grid_limits=(zlim, ylim, xlim),
        grid_origin=origin,
        fields=fields,
        gridding_algo="map_gates_to_grid",
        grid_origin_alt=0.0,
    )

    # Fixing linearity
    # copy = deepcopy(grid.fields[fields[0]]['data'])
    # log_field = 10.0 * ma.log10(copy)
    # grid = add_field_to_grid_object(log_field, grid, field_name=fields[0],
    #                                 dz_field=fields[0])
    # try:
    #     radar.fields[fields[0]]['missing_value'] = [
    #         1.0 * radar.fields[fields[0]]['_FillValue']]
    # except KeyError:
    #     radar.fields[fields[0]]['_FillValue'] = (
    #         radar.fields[fields[0]]['data'].fill_value)
    #     radar.fields[fields[0]]['missing_value'] = [
    #         1.0 * radar.fields[fields[0]]['_FillValue']]

    if for_multidop:
        grid = multidop.angles.add_azimuth_as_field(grid)
        grid = multidop.angles.add_elevation_as_field(grid)

    print(time.time() - bt, " seconds to grid radar")

    return grid


def plot_dbz_vel_grid(
    radar,
    xlim,
    ylim,
    sweep=0,
    dbz_field="corrected_reflectivity",
    vel_field="velocity",
    shapepath="../Data/GENERAL/shapefiles/sao_paulo",
    name_fig="test.png",
):
    """
    Plot quick view of reflectivity and velocity data

    Parameters
    ----------
    radar: Py-ART processed radar mapped data
    sweep: PPI angle to be used
    xlim, ylim: plot limits in lon, lat
        (min, max) in degrees
    dbz_field: name of the reflectivity field
    vel_field: name of the velocity field
    shapepath: shapefile data path
    name_fig: path + name of saved figure

    Returns
    -------
    Panel plot
    """

    display = pyart.graph.RadarMapDisplay(radar)
    fig = plt.figure(figsize=(12, 5))

    fig.add_subplot(121)
    display.plot_ppi_map(
        dbz_field,
        sweep,
        vmin=10,
        vmax=70,
        shapefile=shapepath,
        max_lat=ylim[1],
        min_lat=ylim[0],
        min_lon=xlim[0],
        max_lon=xlim[1],
        lat_lines=np.arange(ylim[0], ylim[1], 0.25),
        lon_lines=np.arange(xlim[0], xlim[1], 0.25),
        cmap="pyart_NWSRef",
        colorbar_label=dbz_field + " (dBZ)",
    )
    fig.add_subplot(122)
    display.plot_ppi_map(
        vel_field,
        sweep,
        vmin=-15,
        vmax=15,
        shapefile=shapepath,
        max_lat=ylim[1],
        min_lat=ylim[0],
        min_lon=xlim[0],
        max_lon=xlim[1],
        lat_lines=np.arange(ylim[0], ylim[1], 0.25),
        lon_lines=np.arange(xlim[0], xlim[1], 0.25),
        cmap="pyart_BuDRd18",
        colorbar_label=vel_field + " (m/s)",
    )
    plt.savefig(name_fig, dpi=300, bbox_inches="tight")


def plot_gridded_maxdbz(
    grid, name_radar, name_base, xlim=[-150000, 150000], ylim=[-150000, 150000]
):
    """
    Using gridded radar data, plot max reflectivity field using matplotlib

    Parameters
    ----------
    grid: gridded radar data
    name_radar: name of the radar to be plotted
    name_base: name of the radar whose grid is based on
    xlim, ylim: plot limits in x, y
        (min, max) in meters
    """

    DZcomp = np.amax(grid.fields["DT"]["data"], axis=0)

    fig = plt.figure(figsize=(6, 5))
    x, y = np.meshgrid(grid.x["data"], grid.y["data"])
    cs = plt.pcolormesh(
        grid.x["data"],
        grid.y["data"],
        DZcomp,
        vmin=0,
        vmax=75,
        cmap="pyart_NWSRef",
    )
    plt.xlim(xlim)
    plt.ylim(ylim)
    plt.colorbar(cs, label="Reflectivity (dBZ)")
    plt.title("Max Reflectivity (filled) of " + name_radar)
    plt.xlabel("Distance east of " + name_base + "  (m)")
    plt.ylabel("Distance north of " + name_base + "  (m)")
    plt.show()


def plot_gridded_velocity(
    grid,
    name_radar,
    name_base,
    height=0,
    xlim=[-150000, 150000],
    ylim=[-150000, 150000],
):
    """
    Using gridded radar data, plot velocity field in a height using matplotlib

    Parameters
    ----------
    grid: gridded radar data
    name_radar: name of the radar to be plotted
    name_base: name of the radar whose grid is based on
    height: height index
    xlim, ylim: plot limits in x, y
        (min, max) in meters
    """

    field = grid.fields["VT"]["data"][height]

    fig = plt.figure(figsize=(6, 5))
    x, y = np.meshgrid(grid.x["data"], grid.y["data"])
    cs = plt.pcolormesh(
        grid.x["data"],
        grid.y["data"],
        field,
        vmin=-15,
        vmax=15,
        cmap="pyart_BuDRd18",
    )
    plt.xlim(xlim)
    plt.ylim(ylim)
    plt.colorbar(cs, label="Velocity (m/s)")
    plt.title(
        ("Doppler Velocity of " + name_radar + " in " + str(height + 1) + " km")
    )
    plt.xlabel("Distance east of " + name_base + "  (m)")
    plt.ylabel("Distance north of " + name_base + "  (m)")
    plt.show()


def adjust_fhc_colorbar_for_pyart(cb, pt_br=False):
    """
    Adjust colorbar aspects.

    Parameters
    ----------
    cb: colorbar
    pt_br: If True, legend will be in portuguese

    Returns
    -------
    cb: adjusted colorbar
    """

    cb.set_ticks(np.arange(1.4, 10, 0.9))
    if pt_br:
        cb.ax.set_yticklabels(
            [
                "Chuvisco",
                "Chuva",
                "Cristais de Gelo",
                "Agregados",
                "Neve Molhada",
                "Gelo Vertical",
                "Graupel DB",
                "Graupel DA",
                "Granizo",
                "Gotas Grandes",
            ]
        )
    else:
        cb.ax.set_yticklabels(
            [
                "Drizzle",
                "Rain",
                "Ice Crystals",
                "Aggregates",
                "Wet Snow",
                "Vertical Ice",
                "LD Graupel",
                "HD Graupel",
                "Hail",
                "Big Drops",
            ]
        )
    cb.ax.set_ylabel("")
    cb.ax.tick_params(length=0)
    return cb


def adjust_meth_colorbar_for_pyart(cb, tropical=False):
    """
    Adjust colorbar aspects.

    Parameters
    ----------
    cb: colorbar
    tropical: True if rain calculations are made in the Tropics

    Returns
    -------
    cb: adjusted colorbar
    """

    if not tropical:
        cb.set_ticks(np.arange(1.25, 5, 0.833))
        cb.ax.set_yticklabels(
            ["R(Kdp, Zdr)", "R(Kdp)", "R(Z, Zdr)", "R(Z)", "R(Zrain)"]
        )
    else:
        cb.set_ticks(np.arange(1.3, 6, 0.85))
        cb.ax.set_yticklabels(
            [
                "R(Kdp, Zdr)",
                "R(Kdp)",
                "R(Z, Zdr)",
                "R(Z_all)",
                "R(Z_c)",
                "R(Z_s)",
            ]
        )
    cb.ax.set_ylabel("")
    cb.ax.tick_params(length=0)
    return cb


def plot_field_panel(
    grid,
    field,
    level,
    fmin,
    fmax,
    lat_index=None,
    lon_index=None,
    date="",
    name_multi="",
    shp_name="",
    hailpad_pos=None,
    zero_height=3.0,
    minusforty_height=10.0,
    grid_spc=0.25,
    cmap=None,
    reverse_cmap=False,
    norm=None,
    xlim=(-48, -46),
    ylim=(-24, -22),
    save_path="./",
    index="",
    hailpad_cs_flag=True,
    pt_br=False,
):
    """
    Using gridded radar data, plot horizontal and vertical
    views:
    - In a specific height (defined by level)
    - In a specific cross-section (defined by lat_index and lon_index)

    Parameters
    ----------
    grid: gridded radar data
    field: field to be plotted
    level: level of horizontal plot
    fmin, fmax: field min and max values
    lat_index, lon_index: tuple of latitude, longitude indexes for cross section
        (end, start) in degrees
    date: date to be shown on main title
    name_multi: acronym with radar name
    shp_name: path of shapefiles
    hailpad_pos: tuple of hailpad position
        (lon, lat)
    zero_height: 0 degrees height
    minusforty_height: -40 degrees height
    grid_spc: grid spacing for horizontal plot
    cmap: define colorbar. None will use Py-ART defauts
    reverse_cmap: If cmap is defined and this is True, the colormap will be
        reversed
    norm: normalization of the colormap
    xlim, ylim: plot limits in lon, lat for horizontal view
        (min, max) in degrees
    save_path: path to save the figures
    index: plot index (positioned in top-left, publication purposes)
    hailpad_cs_flag: If true, plot hailpad position in cross-section
    pt_br: If true, legends will be in portuguese
    """

    # Getting lat-lon-z points
    lons, lats = grid.get_point_longitude_latitude(level)
    xz, z = np.meshgrid(grid.get_point_longitude_latitude()[0], grid.z["data"])

    # Opening colortables
    # if field != 'FH':
    #     if cmap:
    #         cpt = loadCPT(cmap)
    #         if reverse_cmap:
    #             cmap = LinearSegmentedColormap('cpt_r', revcmap(cpt))
    #         else:
    #             cmap = LinearSegmentedColormap('cpt', cpt)

    # Main figure
    display = pyart.graph.GridMapDisplayBasemap(grid)
    fig = plt.figure(figsize=(10, 3.25), constrained_layout=True)
    if field == "FH":
        gs = GridSpec(nrows=1, ncols=8, figure=fig)
    else:
        gs = GridSpec(nrows=1, ncols=7, figure=fig)

    # - Horizontal view
    print("-- Plotting horizontal view --")
    ax1 = fig.add_subplot(gs[0, :3], facecolor="w")
    display.plot_basemap(
        min_lon=xlim[0],
        max_lon=xlim[1],
        min_lat=ylim[0],
        max_lat=ylim[1],
        lon_lines=np.arange(xlim[0], xlim[1], grid_spc),
        lat_lines=np.arange(ylim[0], ylim[1], grid_spc),
        auto_range=False,
        ax=ax1,
    )
    display.basemap.readshapefile(shp_name, "sao_paulo", color="gray")
    # -- Reflectivity (shaded)
    display.plot_grid(
        field,
        level,
        vmin=fmin,
        vmax=fmax,
        cmap=cmap,
        colorbar_flag=False,
        norm=norm,
        ax=ax1,
    )

    # -- Hailpad position
    display.basemap.plot(
        hailpad_pos[0],
        hailpad_pos[1],
        "kX",
        markersize=15,
        markerfacecolor="w",
        alpha=0.75,
        latlon=True,
    )
    # -- Cross section position
    display.basemap.plot(lon_index, lat_index, "k--", latlon=True)
    bmap = display.get_basemap()
    x, y = bmap(lon_index[0], lat_index[0])
    ax1.annotate(
        "A",
        (x, y),
        fontsize=11,
        fontweight="bold",
        fontstretch="condensed",
        ha="center",
        bbox=dict(boxstyle="round,pad=0.2", facecolor="w", alpha=0.75),
    )
    x, y = bmap(lon_index[1], lat_index[1])
    ax1.annotate(
        "B",
        (x, y),
        fontsize=11,
        fontweight="bold",
        fontstretch="condensed",
        ha="center",
        bbox=dict(boxstyle="round,pad=0.2", facecolor="w", alpha=0.75),
    )

    # -- Plot index
    plt.gcf().text(
        0.025,
        0.9,
        index,
        fontsize=20,
        fontweight="bold",
        fontstretch="condensed",
        ha="center",
    )

    # - Vertical view
    print("-- Plotting vertical view --")
    ax2 = fig.add_subplot(gs[0, 3:])
    # -- Reflectivity (shaded)
    display.plot_latlon_slice(
        field,
        vmin=fmin,
        vmax=fmax,
        coord1=(lon_index[0], lat_index[0]),
        coord2=(lon_index[1], lat_index[1]),
        zerodeg_height=zero_height,
        minusfortydeg_height=minusforty_height,
        zdh_col="k",
        cmap=cmap,
        colorbar_flag=False,
        norm=norm,
        dot_pos=hailpad_pos,
        dot_flag=hailpad_cs_flag,
    )
    cb = display.plot_colorbar(
        orientation="vertical", ax=ax2, label=grid.fields[field]["units"]
    )
    if field == "FH":
        cb = adjust_fhc_colorbar_for_pyart(cb)

    # - General aspects
    plt.suptitle(
        name_multi + " " + date,
        weight="bold",
        stretch="condensed",
        size="x-large",
    )
    if field == "FH":
        field_name = grid.fields[field]["standard_name"]
    else:
        if pt_br:
            field_name = grid.fields[field]["standard_name"]
        else:
            field_name = grid.fields[field]["standard_name"].title()
    if pt_br:
        ax1.set_title(field_name + " em " + str(level + 1) + " km")
        ax2.set_title("Corte Vertical de " + field_name)
        ax2.set_ylabel("Distância acima da Superfície (km)")
    else:
        ax1.set_title(str(level + 1) + " km " + field_name)
        ax2.set_title("Cross Section " + field_name)
        ax2.set_ylabel("Distance above Ground (km)")
    ax2.set_xlabel("")
    ax2.grid(linestyle="-", linewidth=0.25)
    ax2.set_ylim(1, 20)

    plt.savefig(
        save_path + name_multi + " " + field_name + " " + date + ".png",
        dpi=300,
        bbox_inches="tight",
        facecolor="none",
        edgecolor="w",
    )


def plot_ppi_panel(
    ppi,
    field,
    level,
    fmin,
    fmax,
    azim=0,
    date="",
    name_multi="",
    shp_name="",
    hailpad_pos=None,
    hailpad_distance=None,
    zero_height=3.0,
    minusforty_height=10.0,
    grid_spc=0.25,
    cmap=None,
    reverse_cmap=False,
    norm=None,
    xlim=(-48, -46),
    ylim=(-24, -22),
    cslim=(100, 200),
    save_path="./",
    index="",
    hailpad_cs_flag=True,
    pt_br=False,
):
    """
    Using radar data, plot horizontal and vertical
    views:
    - In a specific elevation (defined by level)
    - In a specific azimuth (defined by azim)

    Parameters
    ----------
    ppi: radar data
    field: field to be plotted
    level: level of horizontal plot
    fmin, fmax: field min and max values
    azim: azimuth of vertical plot
    date: date to be shown on main title
    name_multi: acronym with radar name
    shp_name: path of shapefiles
    hailpad_pos: tuple of hailpad position
        (lon, lat)
    hailpad_distance: hailpad distance to radar (for azimuth plot)
    zero_height: 0 degrees height
    minusforty_height: -40 degrees height
    grid_spc: grid spacing for horizontal plot
    cmap: define colorbar. None will use Py-ART defauts
    reverse_cmap: If cmap is defined and this is True, the colormap will be
        reversed
    norm: normalization of the colormap
    xlim, ylim: plot limits in lon, lat for horizontal view
        (min, max) in degrees
    cslim: plot x limits in vertical view
        (min, max) in km
    save_path: path to save the figures
    index: plot index (positioned in top-left, publication purposes)
    hailpad_cs_flag: If true, plot hailpad position in cross-section
    pt_br: If true, legends will be in portuguese
    """

    # Opening colortables
    # if field != 'FH':
    #     if cmap:
    #         cpt = loadCPT(cmap)
    #         if reverse_cmap:
    #             cmap = LinearSegmentedColormap('cpt_r', revcmap(cpt))
    #         else:
    #             cmap = LinearSegmentedColormap('cpt', cpt)

    # Main figure
    display = pyart.graph.RadarMapDisplay(ppi)
    fig = plt.figure(figsize=(10, 3.25), constrained_layout=True)

    # - Settings
    # projection = ccrs.LambertConformal(central_latitude=ppi.latitude['data'][0],
    #                                central_longitude=ppi.longitude['data'][0])
    projection = ccrs.PlateCarree()
    if field == "FH":
        gs = GridSpec(nrows=1, ncols=11, figure=fig)
    else:
        gs = GridSpec(nrows=1, ncols=9, figure=fig)

    # - Horizontal view
    print("-- Plotting horizontal view --")
    ax1 = fig.add_subplot(gs[0, :3], facecolor="w", projection=projection)
    ax1.set_position([-0.12, 0.12, 0.7, 0.7])
    display.plot_ppi_map(
        field,
        level,
        vmin=fmin,
        vmax=fmax,
        min_lon=xlim[0],
        max_lon=xlim[1],
        min_lat=ylim[0],
        max_lat=ylim[1],
        lon_lines=np.arange(
            xlim[0] - 2 * grid_spc, xlim[1] + 2 * grid_spc, grid_spc
        ),
        lat_lines=np.arange(
            ylim[0] - 2 * grid_spc, ylim[1] + 2 * grid_spc, grid_spc
        ),
        cmap=cmap,
        colorbar_flag=False,
        norm=norm,
        shapefile=shp_name,
        shapefile_kwargs={
            "crs": projection,
            "edgecolor": "gray",
            "color": "",
            "linewidth": 0.75,
        },
        projection=projection,
        ax=ax1,
    )
    # -- Hailpad position
    display.plot_point(
        hailpad_pos[0],
        hailpad_pos[1],
        "kX",
        markersize=15,
        markerfacecolor="w",
        alpha=0.75,
    )
    # -- Cross section position
    x_cs_0 = cslim[0] * 1000.0 * np.sin(azim * np.pi / 180)
    x_cs_1 = cslim[1] * 1000.0 * np.sin(azim * np.pi / 180)
    y_cs_0 = cslim[0] * 1000.0 * np.cos(azim * np.pi / 180)
    y_cs_1 = cslim[1] * 1000.0 * np.cos(azim * np.pi / 180)
    display.plot_line_xy(
        np.array([x_cs_0, x_cs_1]), np.array([y_cs_0, y_cs_1]), "k--"
    )
    # -- Plot index
    plt.gcf().text(
        0.025,
        0.9,
        index,
        fontsize=20,
        fontweight="bold",
        fontstretch="condensed",
        ha="center",
    )

    # - Vertical view
    print("-- Plotting vertical view --")
    if field == "FH":
        ax2 = fig.add_subplot(gs[0, 5:])
    else:
        ax2 = fig.add_subplot(gs[0, 4:])
    # -- Reflectivity (shaded)
    display.plot_azimuth_to_rhi(
        field,
        azim,
        vmin=fmin,
        vmax=fmax,
        cmap=cmap,
        colorbar_flag=False,
        norm=norm,
        ax=ax2,
    )
    ax2.set_ylim((1, 20))
    ax2.set_xlim((cslim[1], cslim[0]))
    if field == "FH":
        cb = display.plot_colorbar(
            orient="vertical",
            ax=ax2,
            fraction=0.075,
            label=ppi.fields[field]["units"],
        )
        cb = adjust_fhc_colorbar_for_pyart(cb, pt_br)
    else:
        cb = display.plot_colorbar(
            orient="vertical",
            ax=ax2,
            fraction=0.075,
            label=ppi.fields[field]["units"],
        )
    # -- 0 and -40 lines
    ax2.axhline(zero_height, color="k", linestyle=":", linewidth=2)
    ax2.axhline(minusforty_height, color="k", linestyle=":", linewidth=2)
    ax2.annotate(
        r"0$\degree$C",
        (cslim[1] - 1, zero_height - 0.35),
        fontsize=12,
        fontstretch="condensed",
        weight="bold",
        color="k",
        bbox=dict(boxstyle="round,pad=0.2", facecolor="w", alpha=0.75),
    )
    ax2.annotate(
        r"-40$\degree$C",
        (cslim[1] - 1, minusforty_height - 0.35),
        fontsize=12,
        fontstretch="condensed",
        weight="bold",
        color="k",
        bbox=dict(boxstyle="round,pad=0.2", facecolor="w", alpha=0.75),
    )
    # -- Hailpad position
    if hailpad_cs_flag:
        ax2.plot(
            hailpad_distance,
            1,
            "kX",
            clip_on=False,
            markersize=15,
            markerfacecolor="w",
            alpha=0.75,
        )

    # - General aspects
    # plt.tight_layout()
    plt.suptitle(
        name_multi + " " + date,
        weight="bold",
        stretch="condensed",
        size="x-large",
    )
    if field == "FH":
        field_name = ppi.fields[field]["standard_name"]
    else:
        if pt_br:
            field_name = ppi.fields[field]["standard_name"]
        else:
            field_name = ppi.fields[field]["standard_name"].title()
    # -- Axis labels
    ax1.text(
        -0.23,
        0.5,
        "Latitude ($\degree$)",
        va="bottom",
        ha="center",
        rotation="vertical",
        rotation_mode="anchor",
        transform=ax1.transAxes,
    )
    ax1.text(
        0.5,
        -0.17,
        "Longitude ($\degree$)",
        va="bottom",
        ha="center",
        rotation="horizontal",
        rotation_mode="anchor",
        transform=ax1.transAxes,
    )
    if pt_br:
        ax1.set_title(
            "PPI "
            + str(ppi.get_elevation(level)[0])
            + "$\degree$ "
            + field_name
        )
        ax2.set_title("Corte Vertical em Azimute = " + str(azim) + "$\degree$")
        ax2.set_xlabel("Distância do Radar (km)")
        ax2.set_ylabel("Distância acima da Superfície (km)")
    else:
        ax1.set_title(
            "PPI "
            + str(ppi.get_elevation(level)[0])
            + "$\degree$ "
            + field_name
        )
        ax2.set_title("Azimuth = " + str(azim) + "$\degree$ CS " + field_name)
        ax2.set_xlabel("Distance from Radar (km)")
        ax2.set_ylabel("Distance above Ground (km)")
    ax2.grid(linestyle="-", linewidth=0.25)
    ax2.set_ylim(1, 20)

    plt.savefig(
        save_path + name_multi + " PPI " + field_name + " " + date + ".png",
        dpi=300,
        bbox_inches="tight",
        facecolor="none",
        edgecolor="w",
    )

