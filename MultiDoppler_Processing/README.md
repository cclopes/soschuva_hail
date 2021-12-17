# MultiDoppler_Processing [Python, R scripts]
Processing doppler data from 2 (or 3) weather radars using [`MultiDop`](https://github.com/nasa/MultiDop) and [`PyDDA`](https://github.com/openradar/PyDDA) (not fully implemented). Plotting output data with [`Py-ART`](https://github.com/ARM-DOE/pyart).

## Main scripts

- [`plot_uvol_imf_flashes`](plot_uvol_imf_flashes): reading pre-processed updraft volume, ice mass, lightning for correlation maps (figures of updraft vol/ice mass vs flash rate (Deierling et al. 2005, 2008))
- [`get_upvol_im.py`](get_upvol_im.py): extracting updraft volume and ice water mass from MultiDop retrievals and radar data, respectively