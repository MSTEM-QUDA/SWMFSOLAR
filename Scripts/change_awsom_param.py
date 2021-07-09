#!/usr/bin/env python3

import argparse
import datetime as dt
import sys
import subprocess
import warnings
import change_param
from remap_magnetogram import FITS_RECOGNIZE
import download_ADAPT

# -----------------------------------------------------------------------------
def change_param_local(time, map, pfss, scheme=2, poynting_flux=-1.0, new_params={}, DoUseMarker=0):

    if time != 'MapTime':
        # TIME is given with the correct format
        time_input = dt.datetime.strptime(time, "%Y-%m-%dT%H:%M:%S")
        time_param = time.replace('-',',').replace('T',',').replace(':',',')

    if (map == 'NoMap'):
        if time != 'MapTime':
            # Download the ADAPT magnetogram if no map is pvoided
            # default 'fixed', note that the time_input is correctly set.
            filename_map = download_ADAPT.download_ADAPT_magnetogram(time_input)[0]
            print("download the map as: ", filename_map)
        else:
            raise ValueError('No map is provided. Please provide the time '
                             + 'by -t/--time to download the ADAPT map.')
    else:
        # The ADAPT map is provied
        filename_map = map
        
        map_local  = FITS_RECOGNIZE(map)
        time_map   = dt.datetime.strptime(map_local[9], "%Y-%m-%dT%H:%M:%S")

        # Very weird GONG Synoptic map, the map time is a few days after the end of the CR.
        # Use an approximation to get the time corresponding to the central meridian
        if (map_local[0] == 'NSO-GONG Synoptic'):
            CR_number = float(map_local[6])
            time_map = dt.datetime(1853, 11, 9) + dt.timedelta(days=27.2753*(CR_number-0.5))

        if time == 'MapTime':
            # if the user does not provide the time, then set the time based
            # on the time info from the ADAPT map.
            time_param = (str(time_map.year)   + ',' + str(time_map.month) + ',' +
                          str(time_map.day)    + ',' + str(time_map.hour)  + ',' +
                          str(time_map.minute) + ',' + str(time_map.second))

    # set #STARTTIME
    if 'replace' in new_params.keys():
        new_params['replace']['STARTTIME']=time_param
    else:
        new_params['replace'] = {'STARTTIME':time_param}

    if poynting_flux > 0:
        # set #POYNTINGFLUX
        if 'replace' in new_params.keys():
            new_params['replace']['POYNTINGFLUX']='{:<10.3e}'.format(poynting_flux)
        else:
            new_params['replace']={'POYNTINGFLUX':'{:<10.3e}'.format(poynting_flux)}
    elif not 'PoyntingFluxPerBSi' in new_params['change'].keys() and not 'POYNTINGFLUX' in new_params['replace'].keys():
        warnings.warn('PoyntingFluxPerBSi is less than 0, use the PoyntingFluxPerBSi in' +
                      ' the original PARAM.in.')

    if 'add' in new_params.keys():
        commands_add=new_params['add']
        change_param.add_commands(commands_add, DoUseMarker=DoUseMarker)
        change_param.add_commands(commands_add, DoUseMarker=DoUseMarker, filenameIn='FDIPS.in',    filenameOut='FDIPS.in')
        change_param.add_commands(commands_add, DoUseMarker=DoUseMarker, filenameIn='HARMONICS.in',filenameOut='HARMONICS.in')

    if 'rm' in new_params.keys():
        commands_rm=new_params['rm']
        change_param.remove_commands(commands_rm, DoUseMarker=DoUseMarker)
        change_param.remove_commands(commands_rm, DoUseMarker=DoUseMarker, filenameIn='FDIPS.in',     filenameOut='FDIPS.in')
        change_param.remove_commands(commands_rm, DoUseMarker=DoUseMarker, filenameIn='HARMONICS.in', filenameOut='HARMONICS.in')

    if 'replace' in new_params.keys():
        DictReplace = new_params['replace']
        change_param.replace_commands(DictReplace, DoUseMarker=DoUseMarker)
        change_param.replace_commands(DictReplace, DoUseMarker=DoUseMarker, filenameIn='FDIPS.in',     filenameOut='FDIPS.in')
        change_param.replace_commands(DictReplace, DoUseMarker=DoUseMarker, filenameIn='HARMONICS.in', filenameOut='HARMONICS.in')

    if 'change' in new_params.keys():
        DictChange  = new_params['change']
        change_param.change_param_value(DictChange, DoUseMarker=DoUseMarker)
        change_param.change_param_value(DictChange, DoUseMarker=DoUseMarker, filenameIn='FDIPS.in',     filenameOut='FDIPS.in')
        change_param.change_param_value(DictChange, DoUseMarker=DoUseMarker, filenameIn='HARMONICS.in', filenameOut='HARMONICS.in')

    # set the PFSS solver, FDIPS or Harmonics
    if (pfss == 'FDIPS'):
        change_param.add_commands('LOOKUPTABLE', ExtraStr='FDIPS',DoUseMarker=DoUseMarker)
        change_param.remove_commands('MAGNETOGRAM,HARMONICSFILE,HARMONICSGRID', DoUseMarker=DoUseMarker)
    elif (pfss == 'HARMONICS'):
        change_param.remove_commands('LOOKUPTABLE', ExtraStr='FDIPS',DoUseMarker=DoUseMarker)
        change_param.add_commands('HARMONICSFILE,HARMONICSGRID',     DoUseMarker=DoUseMarker)
    else:
        raise ValueError(pfss + ' must be either HARMONICS or FDIPS')

    if scheme == 5:
        change_param.remove_commands('END',ExtraStr='END_2nd_scheme',DoUseMarker=DoUseMarker)

    # prepare each realization map.
    str_exe = str('Scripts/remap_magnetogram.py ' + filename_map)

    subprocess.call(str_exe, shell=True)

# =============================================================================
if __name__ == '__main__':

    # Program initiation
    PROG_DESCRIPTION = ('Script to change PARAM.in if needed and '
                        + ' automatically download the ADAPT map.')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-p', '--poynting_flux',
                            help='(default: -1.0 J/m^2/s/T)',
                            type=float, default=-1)
    ARG_PARSER.add_argument('-t', '--time',
                            help='(default: MapTime)'
                            + 'Use if you want to overwrite PARAM.in time.'
                            + ' Format: yyyy-mm-ddThh:min:sec',
                            type=str, default='MapTime')
    ARG_PARSER.add_argument('-B0', '--pfss',
                            help='(default: HARMONICS.)'
                            + ' Use if you want to specify the PFSS solver.',
                            type=str, default='HARMONICS')
    ARG_PARSER.add_argument('-m', '--map',
                            help='(default: NoMap)'
                            + ' Use if you want to specify the ADAPT map.',
                            type=str, default='NoMap')
    ARG_PARSER.add_argument('-param', '--parameters',
                            help='(default: {})' +
                            ' Use if you want to change the values of the'
                            + ' parameters.',
                            type=list)
    ARGS = ARG_PARSER.parse_args()

    change_param_local(time=ARGS.time, map=ARGS.map, pfss=ARGS.pfss, poynting_flux=ARGS.poynting_flux, DoUseMarker=0)
