#!/bin/sh -xe
##---------------------------------------------------------------------------
##---------------------------------------------------------------------------
## NCEP EMC GLOBAL MODEL VERIFICATION
##
## CONTRIBUTORS: Mallory Row, mallory.row@noaa.gov, NOAA/NWS/NCEP/EMC-VPPGB
## PURPOSE: Used to run the verif_global package in the Global Workflow.
##---------------------------------------------------------------------------
##---------------------------------------------------------------------------

##### List of previously set environment varirables in 
##### global workflow
##### Settings from rocoto 
## RUN_ENVIR, HOMEgfs, EXPDIR,
## CDATE, CDUMP, PDY, cyc, METPCASE
##### Settings from config.base
## KEEPDATA, SENDECF, SENDCOM, SENDDBN,
## gfs_cyc, NET, RUN_ENVIR, envir,  machine
## HOMEDIR, STMP, PTMP, NOSCRUB, WGRIB2
## WGRIB2, CNVGRIB, ACCOUNT, QUEUE, QUEUE_ARCH
## PSLOT, FHMIN_GFS, FHMAX_GF
##### Settings from config.metp
## RUN_GRID2GRID_STEP1, RUN_GRID2OBS_STEP1
## RUN_PRECIP_STEP1, HOMEverif_global
## model_list, model_data_dir_list,
## model_fileformat_list, model_hpssdir_list
## get_data_from_hpss, hpss_walltime
## OUTPUTROOT, model_arch_dir_list
## make_met_data_by, gather_by
## VFRFYBACK_HRS, METPLUS_verbosity,
## MET_verbosity, log_MET_output_to_METplus
## fhr_min, fhr_max, g2g1_type_list
## g2g1_anl_name, g2g1_anl_fileformat_list
## g2g21_grid, g2o1_type_list, g2o1_obtype_upper_air
## g2o1_grid_upper_air, g2o1_fhr_out_upper_air
## g2o1_obtype_conus_sfc, g2o1_grid_conus_sfc
## g2o1_fhr_out_conus_sfc, g2o1_prepbufr_data_runhpss
## precip1_obtype, precip1_accum_length
## precip1_model_bucket_list, precip1_model_varname_list
## precip1_model_fileformat_list, precip1_grid
##### Settings from machinve env
## npe_node_metp_gfs

##### Map the global workflow environment variables
##### to the variables needed to run in EMC_verif-global
export RUN_GRID2GRID_STEP1=${RUN_GRID2GRID_STEP1:-NO}
export RUN_GRID2OBS_STEP1=${RUN_GRID2OBS_STEP1:-NO}
export RUN_PRECIP_STEP1=${RUN_PRECIP_STEP1:-NO}
export HOMEverif_global=${HOMEverif_global:-${HOMEgfs}/sorc/verif-global.fd}
## INPUT DATA SETTINGS
export model_list=${model_list:-$PSLOT}
export model_dir_list=${model_dir_list:-${NOSCRUB}/archive}
export model_fileformat_list=${model_fileformat_list:-"pgbf{lead?fmt=%H}.${CDUMP}.{init?fmt=%Y%m%d%H}"}
export model_hpssdir_list=${model_hpssdir_list:-/NCEPDEV/$HPSS_PROJECT/1year/$USER/$machine/scratch}
export get_data_from_hpss=${get_data_from_hpss:-NO}
export hpss_walltime=${hpss_walltime:-10}
## OUTPUT DATA SETTINGS
export OUTPUTROOT=${OUTPUTROOT:-$RUNDIR/$CDUMP/$CDATE/vrfy/metplus_exp}
export make_met_data_by=${make_met_data_by:-VALID}
export gather_by=${gather_by:-VSDB}
export plot_by=${plot_by:-VALID}
export SENDMETVIEWER=${SENDMETVIEW:-NO}
## DATE SETTINGS
VRFYBACK_HRS=${VRFYBACK_HRS:-00}
## ARCHIVE SETTINGS
export model_arch_dir_list=${model_arch_dir_list:-${NOSCRUB}/archive}
## METPLUS SETTINGS
export METplus_verbosity=${METplus_verbosity:-INFO}
export MET_verbosity=${MET_verbosity:-2}
export log_MET_output_to_METplus=${log_MET_output_to_METplus:-yes}
## FORECAST VERIFICATION SETTINGS
fhr_min=${FHMIN_GFS:-00}
fhr_max=${FHMAX_GFS:-180}
## RESOURCE SETTINGS
export nproc=${npe_node_metp_gfs:-1}
export QUEUE=${QUEUE:-dev}
export QUEUESERV=${QUEUE_ARCH:-dev_transfer}
##### Set up configuration
## OUTPUT DATA SETTINGS
export DATA=$OUTPUTROOT
## DATE AND HOUR SETTINGS
if [ $gfs_cyc = 1 ]; then
    export fcyc_list="$cyc"
    export vhr_list="$cyc"
    export cyc2run="$cyc"
elif [ $gfs_cyc = 2 ]; then
    export fcyc_list="00 12"
    export vhr_list="00 12"
    export cyc2run=00
elif [ $gfs_cyc = 4 ]; then
    export fcyc_list="00 06 12 18"
    export vhr_list="00 06 12 18"
    export cyc2run=00
else
    echo "EXIT ERROR: gfs_cyc must be 1, 2 or 4."                                          
    exit 1
fi
export start_date="$(echo $($NDATE -${VRFYBACK_HRS} $CDATE) | cut -c1-8)"
export end_date="$(echo $($NDATE -${VRFYBACK_HRS} $CDATE) | cut -c1-8)"
## ARCHIVE SETTINGS
export SENDARCH="YES"
## METPLUS SETTINGS
export MET_version="8.1"
export METplus_version="2.1"
## RUNTIME SETTINGS
export MPMD="YES"
## FORECAST VERIFICATION SETTINGS
## some set in config.vrfy
# GRID-TO-GRID STEP 1
export g2g1_type_list=${g2g1_type_list:-"anom pres sfc"}
export g2g1_anl_name=${g2g1_anl_name:-self_anl}
if [ $g2g1_anl_name = self ]; then
    export g2g1_anl_name="self_anl"
fi
export g2g1_anl_fileformat_list=${g2g1_anl_fileformat_list:-"pgbanl.gfs.{valid?fmt=%Y%m%d%H}"}
export g2g1_fcyc_list=$fcyc_list
export g2g1_vhr_list=$vhr_list
export g2g1_fhr_min=$fhr_min
export g2g1_fhr_max=$fhr_max
export g2g1_grid=${g2g1_grid:-G002}
export g2g1_gather_by=$gather_by
export model_data_runhpss=$get_data_from_hpss
# GRID-TO-OBS STEP 1
export g2o1_type_list=${g2o1_type_list:-"upper_air conus_sfc"}
export g2o1_fcyc_list=$fcyc_list
export g2o1_fhr_min=$fhr_min
export g2o1_fhr_max=$fhr_max
export g2o1_obtype_upper_air=${g2o1_obtype_upper_air:-"ADPUPA"}
export g2o1_obtype_conus_sfc=${g2o1_obtype_conus_sfc:-"ONLYSF"}
export g2o1_fhr_out_upper_air=${g2o1_fhr_out_upper_air:-6}
export g2o1_fhr_out_conus_sfc=${g2o1_fhr_out_conus_sfc:-3}
export g2o1_grid_upper_air=${g2o_grid_upper_air:-G003}
export g2o1_grid_conus_sfc=${g2o_grid_conus_sfc:-G104}
export g2o1_gather_by=$gather_by
export g2o1_prepbufr_data_runhpss=${g2o1_prepbufr_data_runhpss:-"NO"}
if [ $g2o1_fhr_out_upper_air -eq 12 ]; then
    export g2o1_vhr_list_upper_air="00 12"
elif [ $g2o1_fhr_out_upper_air -eq 6 ]; then
    export g2o1_vhr_list_upper_air="00 06 12 18"
else
    echo "ERROR: g2o1_fhr_out_upper_air=$g2o1_fhr_out_upper_air is not supported"
fi
if [ $g2o1_fhr_out_conus_sfc -eq 12 ]; then
    export g2o1_vhr_list_conus_sfc="00 12"
elif [ $g2o1_fhr_out_conus_sfc -eq 6 ]; then
    export g2o1_vhr_list_conus_sfc="00 06 12 18"
elif [ $g2o1_fhr_out_conus_sfc -eq 3 ]; then
    export g2o1_vhr_list_conus_sfc="00 03 06 09 12 15 18 21"
else
    echo "ERROR: g2o1_fhr_out_conus_sfc=$g2o1_fhr_out_conus_sfc is not supported"
fi
# PRECIP STEP 1
export precip1_fcyc_list=$fcyc_list
export precip1_fhr_min=$fhr_min
export precip1_fhr_max=$fhr_max
export precip1_obtype=${precip1_obtype:-ccpa}
export precip1_accum_length=${precip1_accum_length:-24}
export precip1_model_bucket_list=${precip_model_bucket_list:-06}
export precip1_model_varname_list=${precip_model_varname_list:-APCP}
export precip1_model_fileformat_list=${precip1_model_filefomat_list:-$model_fileformat_list}
export precip1_grid=${precip1_grid:-G211}
export precip1_gather_by=$gather_by
export precip1_obs_data_runhpss="YES"

echo
## Set up output location
mkdir -p $DATA
cd $DATA
if [ $METPCASE = g2g1 ]; then
    RUN_DIR="grid2grid_step1"
fi
if [ $METPCASE = g2o1 ]; then
    RUN_DIR="grid2obs_step1"
fi
if [ $METPCASE = pcp1 ]; then
    RUN_DIR="precip_step1"
fi
if [ -d $RUN_DIR ]; then
    rm -r $RUN_DIR
fi

## Get machine
python $HOMEverif_global/ush/get_machine.py
status=$?
[[ $status -ne 0 ]] && exit $status
[[ $status -eq 0 ]] && echo "Succesfully ran get_machine.py"
echo
if [ -s config.machine ]; then
    . $DATA/config.machine
    status=$?
    [[ $status -ne 0 ]] && exit $status
    [[ $status -eq 0 ]] && echo "Succesfully sourced config.machine"
    echo
fi

## Load modules and set machine specific variables
if [ $machine != "HERA" -a $machine != "WCOSS_C" -a $machine != "WCOSS_DELL_P3" ]; then
    echo "ERROR: $machine is not supported"
    exit 1
fi

. $HOMEverif_global/ush/load_modules.sh $machine $MET_version $METplus_version
status=$?
[[ $status -ne 0 ]] && exit $status
[[ $status -eq 0 ]] && echo "Succesfully loaded modules"
echo

## Installations for verif_global, MET, and METplus
export HOMEverif_global=$HOMEverif_global
export PARMverif_global=$HOMEverif_global/parm
export FIXverif_global=$FIXgfs/fix_verif
export USHverif_global=$HOMEverif_global/ush
export UTILverif_global=$HOMEverif_global/util
export EXECverif_global=$HOMEverif_global/exec
export HOMEMET=$HOMEMET
export HOMEMETplus=$HOMEMETplus
export PARMMETplus=$HOMEMETplus/parm
export USHMETplus=$HOMEMETplus/ush
export PATH="${USHMETplus}:${PATH}"
export PYTHONPATH="${USHMETplus}:${PYTHONPATH}"

## Machine and user specific paths
if [ $machine = "HERA" ]; then
    export gstat="/scratch1/NCEPDEV/global/Fanglin.Yang/stat"
    export prepbufr_arch_dir="/scratch1/NCEPDEV/global/Fanglin.Yang/stat/prepbufr"
    export ccpa_24hr_arch_dir="/scratch1/NCEPDEV/global/Mallory.Row/obdata/ccpa_accum24hr"
elif [ $machine = "WCOSS_C" ]; then
    export gstat="/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/stat"
    export prepbufr_arch_dir="/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/prepbufr"
    export ccpa_24hr_arch_dir="/gpfs/hps3/emc/global/noscrub/Mallory.Row/obdata/ccpa_accum24hr"
elif [ $machine = "WCOSS_DELL_P3" ]; then
    export gstat="/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/stat"
    export prepbufr_arch_dir="/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/prepbufr"
    export ccpa_24hr_arch_dir="/gpfs/dell2/emc/verification/noscrub/Mallory.Row/obdata/ccpa_accum24hr"
fi

## Some operational directories
export prepbufr_prod_upper_air_dir="/gpfs/dell1/nco/ops/com/gfs/prod"
export prepbufr_prod_conus_sfc_dir="/gpfs/dell1/nco/ops/com/nam/prod"
export ccpa_24hr_prod_dir="/gpfs/dell1/nco/ops/com/verf/prod"

## Do checks on switches to run verification for
if [ $METPCASE = g2g1 ]; then
    RUN_GRID2OBS_STEP1=NO
    RUN_PRECIP_STEP1=NO
fi
if [ $METPCASE = g2o1 ]; then
    RUN_GRID2GRID_STEP1=NO
    RUN_PRECIP_STEP1=NO
fi
if [ $METPCASE = pcp1 ]; then
    RUN_GRID2GRID_STEP1=NO
    RUN_GRID2OBS_STEP1=NO
fi
if [ $cyc != $cyc2run ]; then 
    RUN_GRID2GRID_STEP1=NO 
    RUN_GRID2OBS_STEP1=NO 
    RUN_PRECIP_STEP1=NO
fi
if [ ${start_date}${cyc2run} -le $SDATE ]; then
    RUN_GRID2GRID_STEP1=NO
    RUN_GRID2OBS_STEP1=NO
    RUN_PRECIP_STEP1=NO
fi
for fcyc in $fcyc_list; do
    if [ ${start_date}${fcyc} -le $SDATE ]; then
         RUN_GRID2GRID_STEP1=NO
         RUN_GRID2OBS_STEP1=NO
         RUN_PRECIP_STEP1=NO
    fi
done
precip_back_hours=$((VRFYBACK_HRS + precip1_accum_length))
precip_check_date="$(echo $($NDATE -${precip_back_hours} $CDATE) | cut -c1-8)"
if [ ${precip_check_date}${cyc2run} -le $SDATE ]; then
    RUN_PRECIP_STEP1=NO
fi
for fcyc in $fcyc_list; do
    if [ ${precip_check_date}${fcyc} -le $SDATE ]; then
         RUN_PRECIP_STEP1=NO
    fi
done

## Run METplus
echo "=============== RUNNING METPLUS ==============="
if [ $RUN_GRID2GRID_STEP1 = YES ] ; then
    echo
    echo "===== RUNNING GRID-TO-GRID STEP 1 VERIFICATION  ====="
    echo "===== creating partial sum data for grid-to-grid verifcation using METplus ====="
    export RUN="grid2grid_step1"
    $HOMEverif_global/scripts/exgrid2grid_step1.sh
fi 

if [ $RUN_GRID2OBS_STEP1 = YES ] ; then
    echo
    echo "===== RUNNING GRID-TO-OBSERVATIONS STEP 1 VERIFICATION  ====="
    echo "===== creating partial sum data for grid-to-observations verifcation using METplus ====="
    export RUN="grid2obs_step1"
    $HOMEverif_global/scripts/exgrid2obs_step1.sh
fi  

if [ $RUN_PRECIP_STEP1 = YES ] ; then
    echo
    echo "===== RUNNING PRECIPITATION STEP 1 VERIFICATION  ====="
    echo "===== creating partial sum data for precipitation verifcation using METplus ====="
    export RUN="precip_step1"
    $HOMEverif_global/scripts/exprecip_step1.sh
fi
