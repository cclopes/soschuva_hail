# -*- coding: utf-8 -*-
"""
"""

import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader
from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER
import matplotlib.pyplot as plt
import numpy as np

import custom_cbars


def plot_main_map(shapefolder, grid_spc=20, extent=[-180, 180, -90, 90]):
    """
    """

    proj = ccrs.PlateCarree(central_longitude=-57.5)
    trans = ccrs.PlateCarree()
    fig, ax = plt.subplots(figsize=(5, 6), facecolor='w',
                           subplot_kw=dict(projection=proj))

    ax.set_extent(extent, crs=trans)

    ax.add_geometries(
        shpreader.Reader(shapefolder + 'estadosl_2007').geometries(), trans,
        linewidth=0.3, facecolor='none', edgecolor='darkslategray'
    )
    ax.add_geometries(
        shpreader.Reader(
            shapefolder + 'ne_10m_admin_0_countries'
        ).geometries(),
        trans, linewidth=0.5, facecolor='none', edgecolor='darkslategray'
    )

    gl = ax.gridlines(crs=trans, xlocs=np.arange(-180, 181, grid_spc),
                      ylocs=np.arange(-80, 90, grid_spc), draw_labels=True)
    gl.xlabels_top = gl.ylabels_right = False
    gl.xformatter = LONGITUDE_FORMATTER
    gl.yformatter = LATITUDE_FORMATTER

    return fig, ax, trans


def plot_sfc_jets(data, fig_asp, **kwargs):
    """
    """

    fig, ax, trans = plot_main_map(extent=fig_asp['extent'],
                                   grid_spc=fig_asp['grid_spacing'],
                                   shapefolder=fig_asp['shapefiles_path'],
                                   **kwargs)

    # MSLP
    mslp_cont = ax.contour(
        data.lon, data.lat, data.mslp, levels=np.arange(950, 1050, 4),
        colors='k', linewidths=1, zorder=3, transform=trans)
    plt.clabel(mslp_cont, np.arange(950, 1050, 4), inline=True, fmt='%1i',
               fontsize=9, use_clabeltext=True)

    # Thickness
    thick_levs = (np.arange(0, 540, 6),
                  np.array([540]),
                  np.arange(546, 700, 6))
    thick_colors = ('tab:blue', 'b', 'tab:red')
    for lev, color in zip(thick_levs, thick_colors):
        th_cont = ax.contour(
            data.lon, data.lat, data.thick, colors=color, levels=lev,
            linewidths=1, linestyles='dashed', zorder=2, transform=trans)
        plt.clabel(th_cont, lev, inline=True, fmt='%1i', fontsize=9,
                   use_clabeltext=True)

    # Wind
    wind_shaded = ax.contourf(
        data.lon, data.lat, data.wind, levels=np.arange(0, 120, 10),
        zorder=1, transform=trans, cmap='wind')
    fig.colorbar(wind_shaded, spacing='uniform',
                 # label='250 hPa Wind Speed (' + r'$m s^{-1}$' + ')',
                 label='Vento 250 hPa (' + r'$m s^{-1}$' + ')',  # pt-br
                 aspect=fig_asp['cbar_aspect'], shrink=fig_asp['cbar_shrink'],
                 pad=0.025)

    plt.title(data.title_plot, weight='bold', stretch='condensed',
              size='medium', position=(0.55, 1))

    # Saving
    # plt.savefig(('figures/ERA5_' + fig_asp['fig_type'] + data.title_figure +
    #              '.png'), dpi=300, transparent=True, bbox_inches='tight')
    # pt-br
    plt.savefig(('figures/ERA5_' + fig_asp['fig_type'] + data.title_figure +
                 '_ptbr.png'), dpi=300, transparent=True, bbox_inches='tight')
    plt.close()


def plot_cape_shear(data, fig_asp, **kwargs):
    """
    """

    fig, ax, trans = plot_main_map(extent=fig_asp['extent'],
                                   grid_spc=fig_asp['grid_spacing'],
                                   shapefolder=fig_asp['shapefiles_path'],
                                   **kwargs)

    # Geopotential height
    z_cont = ax.contour(
        data.lon, data.lat, data.z, levels=np.arange(100, 300, 3),
        colors='k', linewidths=1, zorder=3, transform=trans)
    plt.clabel(z_cont, np.arange(100, 300, 3), inline=True, fmt='%1i',
               fontsize=9, use_clabeltext=True)

    # CIN
    # cin_cont = ax.contour(
    #     data.lon, data.lat, data.cin,
    #     levels=np.arange(-1000, 1000, 50), colors='b', linewidths=0.5,
    #     zorder=2, transform=trans)
    # plt.clabel(cin_cont, np.arange(-1000, 1000, 50), inline=True, fmt='%1i',
    #            fontsize=7, use_clabeltext=True)

    # Wind shear
    ax.barbs(data.lon, data.lat, data.u, data.v, regrid_shape=15,
             zorder=4, transform=trans, length=5, linewidth=0.5,
             flip_barb=True)

    # CAPE
    cape_shaded = ax.contourf(
        data.lon, data.lat, data.cape, levels=np.arange(0, 5500, 500),
        zorder=1, transform=trans, cmap='cape')
    fig.colorbar(cape_shaded, spacing='uniform',
                 label='CAPE (' + r'$J kg^{-1}$' + ')',
                 aspect=fig_asp['cbar_aspect'], shrink=fig_asp['cbar_shrink'],
                 pad=0.025)

    plt.title(data.title_plot, weight='bold', stretch='condensed',
              size='medium', position=(0.55, 1))

    # Saving
    # plt.savefig(('figures/ERA5_' + fig_asp['fig_type'] + data.title_figure +
    #              '.png'), dpi=300, transparent=True, bbox_inches='tight')
    # pt-br
    plt.savefig(('figures/ERA5_' + fig_asp['fig_type'] + data.title_figure +
                 '_ptbr.png'), dpi=300, transparent=True, bbox_inches='tight')
    plt.close()
