from __future__ import (print_function, division)
import os
import numpy as np
import netCDF4 as netcdf
import re
import plot_util as plot_util
import maps2d_plot_util as maps2d_plot_util
import warnings
import logging
import datetime
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

warnings.filterwarnings('ignore')
plt.rcParams['font.weight'] = 'bold'
plt.rcParams['axes.labelsize'] = 15
plt.rcParams['axes.labelweight'] = 'bold'
plt.rcParams['xtick.labelsize'] = 15
plt.rcParams['ytick.labelsize'] = 15
plt.rcParams['axes.titlesize'] = 15
plt.rcParams['axes.titleweight'] = 'bold'
plt.rcParams['axes.formatter.useoffset'] = False
###import cmocean
###cmap_diff = cmocean.cm.balance
cmap_diff = plt.cm.coolwarm
noaa_logo_img_array = matplotlib.image.imread(
    os.path.join(os.environ['USHverif_global'], 'plotting_scripts', 'noaa.png')
)

# Read in environment variables
DATA = os.environ['DATA']
RUN = os.environ['RUN']
make_met_data_by = os.environ['make_met_data_by']
plot_by = os.environ['plot_by']
START_DATE = os.environ['START_DATE']
END_DATE = os.environ['END_DATE']
forecast_to_plot = os.environ['forecast_to_plot']
hr_beg = os.environ['hr_beg']
hr_end = os.environ['hr_end']
hr_inc = os.environ['hr_inc']
regrid_to_grid = os.environ['regrid_to_grid']
latlon_area = os.environ['latlon_area'].split(' ')
var_group_name = os.environ['var_group_name']
var_name = os.environ['var_name']
var_levels = os.environ['var_levels'].split(', ')
verif_case_type = os.environ['verif_case_type']
if verif_case_type == 'gdas':
     plot_stats_list = ['bias', 'rmse']

# Set up information
py_map_pckg = os.environ['py_map_pckg']
if py_map_pckg == 'cartopy':
    import cartopy.crs as ccrs
    from cartopy.util import add_cyclic_point
    from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
elif py_map_pckg == 'basemap':
    from mpl_toolkits.basemap import Basemap, addcyclic
llcrnrlat_val = float(latlon_area[0])
urcrnrlat_val = float(latlon_area[1])
lat_ticks = np.linspace(llcrnrlat_val, urcrnrlat_val, 7, endpoint=True)
env_var_model_list = []
regex = re.compile(r'model(\d+)$')
for key in os.environ.keys():
    result = regex.match(key)
    if result is not None:
        env_var_model_list.append(result.group(0))
env_var_model_list = sorted(env_var_model_list, key=lambda m: m[-1])
nmodels = len(env_var_model_list)
make_met_data_by_hrs = []
hr = int(hr_beg) * 3600
while hr <= int(hr_end)*3600:
    make_met_data_by_hrs.append(str(int(hr/3600)).zfill(2)+'Z')
    hr+=int(hr_inc)
make_met_data_by_hrs_title = ', '.join(make_met_data_by_hrs)
if verif_case_type == 'gdas':
    forecast_to_plot_title = (
        'First Guess Hour '+forecast_to_plot
    )
else:
    forecast_to_plot_title = forecast_to_plot
START_DATE_dt = datetime.datetime.strptime(START_DATE, '%Y%m%d')
END_DATE_dt = datetime.datetime.strptime(END_DATE, '%Y%m%d')
dates_title = (make_met_data_by.lower()+' '
               +START_DATE_dt.strftime('%d%b%Y')+'-'
               +END_DATE_dt.strftime('%d%b%Y'))
nvar_levels = len(var_levels)
var_level_num_list = []
for var_level in var_levels:
    var_level_num_list.append(var_level.replace('hPa', ''))
var_levels_num = np.asarray(var_level_num_list, dtype=float)

# Get input and output directories
series_analysis_file_dir = os.path.join(DATA, RUN, 'metplus_output',
                                        'make_met_data_by_'+make_met_data_by,
                                        'series_analysis', verif_case_type,
                                        var_group_name)
plotting_out_dir_imgs = os.path.join(DATA, RUN, 'metplus_output',
                                     'plot_by_'+plot_by,
                                     verif_case_type, var_group_name,
                                     'imgs')
if not os.path.exists(plotting_out_dir_imgs):
    os.makedirs(plotting_out_dir_imgs)

# Build data array for all models for
# all levels
print("Working on zonal mean plots for "+var_name)
model_num = 0
for env_var_model in env_var_model_list:
    model_num+=1
    model = os.environ[env_var_model]
    var_level_num = 0 
    for var_level in var_levels:
        var_level_num+=1
        var_info_title, levels, levels_diff, cmap, var_scale = (
            maps2d_plot_util.get_maps2d_plot_settings(var_name, var_level)
        )
        model_series_analysis_netcdf_file = os.path.join(
            series_analysis_file_dir, model,
            forecast_to_plot+'_'+var_name+'_'
            +var_level.replace(' ', '')+'.nc'
        )
        if os.path.exists(model_series_analysis_netcdf_file):
            print(model_series_analysis_netcdf_file+" exists")
            model_data = netcdf.Dataset(model_series_analysis_netcdf_file)
            model_data_lat = model_data.variables['lat'][:]
            model_data_lon = model_data.variables['lon'][:]
            model_data_variable_names = []
            for var in model_data.variables:
                model_data_variable_names.append(str(var))
            if 'series_cnt_FBAR' in model_data_variable_names:
                model_data_series_cnt_FBAR =  (
                    model_data.variables['series_cnt_FBAR'][:] * var_scale
                )
            else:
                print("WARNING: FBAR values for "+model+" "
                      +"not in file...setting to NaN")
                model_data_series_cnt_FBAR = np.full(
                    (len(model_data_lat), len(model_data_lon)), np.nan
                )
            if 'series_cnt_OBAR' in model_data_variable_names:
                model_data_series_cnt_OBAR =  (
                    model_data.variables['series_cnt_OBAR'][:] * var_scale
                )
            else:
                print("WARNING: OBAR values for "+model+" "
                      +"not in file...setting to NaN")
                model_data_series_cnt_OBAR = np.full(
                    (len(model_data_lat), len(model_data_lon)), np.nan
                )
            if np.ma.is_masked(model_data_series_cnt_FBAR):
                np.ma.set_fill_value(model_data_series_cnt_FBAR, np.nan)
                model_data_series_cnt_FBAR = (
                    model_data_series_cnt_FBAR.filled()
                )
            if np.ma.is_masked(model_data_series_cnt_OBAR):
                np.ma.set_fill_value(model_data_series_cnt_OBAR, np.nan)
                model_data_series_cnt_OBAR = (
                    model_data_series_cnt_OBAR.filled()
                )
            if not 'model_var_levels_zonalmean_FBAR' in locals():
                model_var_levels_zonalmean_FBAR = np.ones(
                    [nmodels, nvar_levels, len(model_data_lat)]
                ) * np.nan
            if not 'model_var_levels_zonalmean_OBAR' in locals():
                model_var_levels_zonalmean_OBAR = np.ones(
                    [nmodels, nvar_levels, len(model_data_lat)]
                ) * np.nan
            model_var_levels_zonalmean_FBAR[model_num-1,var_level_num-1,:] = (
                model_data_series_cnt_FBAR.mean(axis=1)
            )
            model_var_levels_zonalmean_OBAR[model_num-1,var_level_num-1,:] = (
                model_data_series_cnt_OBAR.mean(axis=1)
            )
        else:
            print("WARNING: "+model_series_analysis_netcdf_file+" "
                  +"does not exist")
# Set up plot
for stat in plot_stats_list:
    if stat == 'bias':
        stat_title = 'Bias of GDAS Analysis Increments'
    elif stat == 'rmse':
        stat_title = 'Root Mean Square Error of GDAS Analysis Increments'
    nsubplots = nmodels + 1
    if nsubplots > 8:
        print("Too many subplots requested. "
              "Current maximum is 8.")
        exit(1)
    if nsubplots == 1:
        fig = plt.figure(figsize=(10,15))
        gs = gridspec.GridSpec(1,1)
    elif nsubplots == 2:
        fig = plt.figure(figsize=(10,15))
        gs = gridspec.GridSpec(2,1)
        gs.update(hspace=0.2)
    elif nsubplots > 2 and nsubplots <= 4:
        fig = plt.figure(figsize=(20,15))
        gs = gridspec.GridSpec(2,2)
        gs.update(wspace=0.2, hspace=0.2)
    elif nsubplots > 4 and nsubplots <= 6:
        fig = plt.figure(figsize=(30,15))
        gs = gridspec.GridSpec(2,3)
        gs.update(wspace=0.2, hspace=0.2)
    elif nsubplots > 6 and nsubplots <= 9:
       fig = plt.figure(figsize=(30,21))
       gs = gridspec.GridSpec(3,3)
       gs.update(wspace=0.2, hspace=0.2)    
    model_num = 0
    for env_var_model in env_var_model_list:
        model_num+=1
        model = os.environ[env_var_model]
        model_obtype = os.environ[env_var_model+'_obtype']
        model_plot_name = os.environ[env_var_model+'_plot_name']
        x, y = np.meshgrid(model_data_lat, var_levels_num)
        if verif_case_type == 'gdas':
            # Set up control analysis subplot map and title and plot
            if model_num == 1:
                print("Plotting "+model_plot_name+" analysis")
                model1 = model
                model1_plot_name = model_plot_name
                model1_var_levels_zonalmean_OBAR = (
                    model_var_levels_zonalmean_OBAR[model_num-1,:,:]
                )
                ax_cntrl = plt.subplot(gs[0])
                ax_cntrl.set_xlabel('Latitude')
                ax_cntrl.set_xticks(lat_ticks)
                ax_cntrl.set_ylabel('Pressure Level')
                ax_cntrl.set_yscale("log")
                ax_cntrl.invert_yaxis()
                ax_cntrl.minorticks_off()
                ax_cntrl.set_yticks(var_levels_num)
                ax_cntrl.set_yticklabels(var_level_num_list)
                ax_cntrl.set_title('A '+model_plot_name, loc='left')
                if np.all(np.isnan(levels)):
                    if np.isnan(np.nanmax(model1_var_levels_zonalmean_OBAR)):
                        levels_max = 1
                    else:
                        levels_max = int(
                            np.nanmax(model1_var_levels_zonalmean_OBAR)
                        ) + 1
                    if np.isnan(np.nanmin(model1_var_levels_zonalmean_OBAR)):
                        levels_min = -1
                    else:
                        levels_min = int(
                            np.nanmin(model1_var_levels_zonalmean_OBAR)
                        ) - 1
                    levels = np.linspace(levels_min, levels_max, 11, endpoint=True)
                if np.count_nonzero(
                            ~np.isnan(model1_var_levels_zonalmean_OBAR)) != 0:
                    CF1 = ax_cntrl.contourf(x, y, model1_var_levels_zonalmean_OBAR,
                                      levels=levels, cmap=cmap,
                                      extend='both')
                    C1 = ax_cntrl.contour(x, y, model1_var_levels_zonalmean_OBAR,
                                    levels=levels, colors='k',
                                    linewidths=1.0, extend='both')
                    C1labels = ax_cntrl.clabel(C1, C1.levels, fmt='%g', colors='k')
            # Set up model subplot map and title and plot
            subplot_num =  model_num
            ax = plt.subplot(gs[subplot_num])
            ax.set_xlabel('Latitude')
            ax.set_xticks(lat_ticks)
            ax.set_ylabel('Pressure Level')
            ax.set_yscale("log")
            ax.invert_yaxis()
            ax.minorticks_off()
            ax.set_yticks(var_levels_num)
            ax.set_yticklabels(var_level_num_list)
            if stat == 'bias':
                print("Plotting "+model+" increment bias")
                ax.set_title('(A-B) '+model_plot_name, loc='left')
                stat_data = (
                    model_var_levels_zonalmean_OBAR[model_num-1,:,:]
                    - model_var_levels_zonalmean_FBAR[model_num-1,:,:]
                )
            elif stat == 'rmse':
                if model_num == 1:
                    print("Plotting "+model1+" increment RMSE")
                    ax.set_title('RMSE(A-B) '+model_plot_name, loc='left')
                    stat_data = np.sqrt(
                        (model_var_levels_zonalmean_OBAR[model_num-1,:,:]
                         -model_var_levels_zonalmean_FBAR[model_num-1,:,:])**2
                    )
                    model1_stat_data = stat_data
                else:
                    print("Plotting "+model+" - "+model1+" "
                          +"increment RMSE")
                    ax.set_title('RMSE(A-B) '+model_plot_name
                                 +'-'+model1_plot_name, loc='left')
                    stat_data = np.sqrt(
                        (model_var_levels_zonalmean_OBAR[model_num-1,:,:]
                         -model_var_levels_zonalmean_FBAR[model_num-1,:,:])**2
                    ) - model1_stat_data
            if np.count_nonzero(
                    ~np.isnan(stat_data)) != 0:
                CF = ax.contourf(x, y, stat_data,
                                 levels=levels_diff, cmap=cmap_diff,
                                 extend='both')
    # Final touches and save plot
    cax = fig.add_axes([0.1, 0.0, 0.8, 0.05])
    cbar = fig.colorbar(CF, cax=cax, orientation='horizontal',
                        ticks=levels_diff)
    cbar.ax.set_xlabel('Difference')
    full_title = (
        stat_title+' '+var_info_title.partition(' ')[2]+' '
        +'Zonal Mean Error\n'
        +dates_title+' '+make_met_data_by_hrs_title+', '
        +forecast_to_plot_title
    )
    fig.suptitle(full_title, fontsize=18, fontweight='bold')
    noaa_img_axes = fig.add_axes([-0.01, 0.0, 0.01, 0.01])
    noaa_img_axes.axes.get_xaxis().set_visible(False)
    noaa_img_axes.axes.get_yaxis().set_visible(False)
    noaa_img_axes.axis('off')
    fig.figimage(noaa_logo_img_array, 1, 1, zorder=1, alpha=0.5)
    savefig_name = os.path.join(plotting_out_dir_imgs,
                                verif_case_type+'_'+stat+'_'+var_group_name
                                +'_'+var_name+'_zonalmean.png')
    print("Saving image as "+savefig_name)
    plt.savefig(savefig_name, bbox_inches='tight')
    plt.close()
