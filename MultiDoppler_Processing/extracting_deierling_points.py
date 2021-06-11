import datathief as dt

filename = "Data/GENERAL/deierling_figs/deierling_2008_upvol_meanflashes.png"
xlim = [1e9, 1e13]
ylim = [1e-1, 1e3]
data = dt.datathief(filename, xlim=xlim, ylim=ylim)