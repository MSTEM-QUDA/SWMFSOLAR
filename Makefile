SHELL=/bin/bash

# Include the link to the Makefile.def from the SWMF used
-include SWMF/Makefile.def

MYDIR  = $(shell echo `pwd -P`)
SIMDIR = Runs
RESDIR = Runs
IDLDIR = ${DIR}/share/IDL/Solar
PYDIR  = ${MYDIR}/Scripts

MODEL = AWSoM
PFSS  = HARMONICS

TIME = MapTime
MAP  = NoMap

EVTIME = none
DTEV   = -7

POYNTINGFLUX   = -1.0

PARAM = Default

REALIZATIONS    = 1,2,3,4,5,6,7,8,9,10,11,12
REALIZATIONLIST = $(foreach v, $(shell echo ${REALIZATIONS} | tr , ' '), $(shell printf '%02d' $(v)))

RESTART   = F
DOINSTALL = T

JOBNAME  = amap

SimDirList = $(sort $(dir $(wildcard run[0-9]*_*/)))
ResDirList = $(subst ${MYDIR}/Results/,,${FullResDirList})
FullResDirList = $(sort $(dir $(wildcard ${MYDIR}/Results/run[0-9]*_*/)))

FullResDir        = ${MYDIR}/Results/${RESDIR}
FullRunDirList    = $(sort $(dir $(wildcard ${MYDIR}/${SIMDIR}/run[01][0-9]/)))
FullResRunDirList = $(sort $(dir $(wildcard ${FullResDir}/run[01][0-9]/)))

help: 
	@echo "*******************************************************************************"
	@echo "This makefile uses pyfits (in SWMF/share/Python/. "
	@echo "There is a link in SWMFSOLAR/Scripts to pyfits. "
	@echo "Check the python version with python --version. Should be 3.7 or above."
	@echo ""
	@echo "On Pleiades, add 'module load python3/3.7.0' in the .cashrc or .bashrc file."
	@echo "On Derecho, python packages are avail. via conda env, intel compiler is reloaded"
	@echo "This is temp. fix to load the correct compiler while using Python, UCAR may fix it"
	@echo "module load conda; conda activate npl, module load intel"
	@echo "On Frontera, the default python is python2 and it is a link in /bin. "
	@echo "Make a bin folder in your home folder and create a link to python3.7:"
	@echo "  mkdir ~/bin; cd ~/bin/; ln -s `which python3.7` ~/bin/python"
	@echo '  setenv PATH ~/bin/:$${PATH} # add it to the beginning of PATH in .cshrc'
	@echo "*******************************************************************************"
	@echo ""
	@echo "Examples:"
	@echo "  make adapt_run_w_compile MODEL=AWSoM  "
	@echo "       (configure SWMF and run AWSoM with 12 ADAPT realizations with B0 "
	@echo "        from Harmonics)"
	@echo "  make adapt_run MODEL=AWSoM  "
	@echo "       (run AWSoM   with 12 ADAPT realizations with B0 from Harmonics)"
	@echo "  make adapt_run MODEL=AWSoMR "
	@echo "       (run AWSoM-R with the 12 ADAPT realizations with B0 from Harmonics)"
	@echo "  make adapt_run MODEL=AWSoM REALIZATIONS=1 MAP=hmi.dat PFSS=FDIPS"
	@echo "       (run AWSoM with a single map named hmi.dat and use FDIPS)"
	@echo ""
	@echo "NOTE: "
	@echo "  adapt_run does NOT re-configure/compile SWMF to save time!"
	@echo "  adapt_run_w_compile will uninstall the SWMF, reinstall and compile the code."
	@echo ""
	@echo "After all simulations are finished post-process the results into Results/event1:"
	@echo ""
	@echo "  make check_postproc RESDIR=event1"
	@echo ""
	@echo "Comparing the simulations with observations is best to do on a local machine."
	@echo "This requires SSWIDL and share/IDL/Solar has to be properly set up. Use"
	@echo ""
	@echo "  make check_compare RESDIR=event1 MODEL=AWSoMR"
	@echo ""
	@echo "to compare Results/event1 with observations saved into Results/obsdata."
	@echo "MODEL is needed for plot legends."
	@echo ""
	@echo "Options:"
	@echo " MODEL=AWSoM         - select model: 'AWSoM' (default) or 'AWSoMR' (case sensitive)"
	@echo " SIMDIR=run01_test   - set name of simulation directory. Default is 'Runs'"
	@echo " RESDIR=run01_test   - set name of result directory in Results/. Default is 'Runs'"
	@echo " PFSS=HARMONICS      - set potential field solver: HARMONICS (default) or FDIPS"
	@echo " TIME=2012-1-1T1:1:1 - set the start time of the simulation, format is "
	@echo "                       YYYY-MM-DDTHH:MM:SC, default is MapTime (time of map)".
	@echo " POYNTINGFLUX=1.0e6, - set the Poynting flux, default is in the PARAM.in file."
	@echo " MAP=filename        - set the input map if desired. Default is 'NoMap'."
	@echo " REALIZATIONS=1,2    - list the realizations. Default is '1,2,3,4,5,6,7,8,9,10,11,12'"
	@echo " JOBNAME=amap        - set the job name. Default is 'amap' with "
	@echo "                       realization appensed, e.g. 'amap01'"
	@echo "                       Some systems limit the length of job name to 6 letters"
	@echo ""
	@echo "Notes:"
	@echo "User can set either TIME or MAP, or BOTH. And the following will occur:"
	@echo " 1. Both TIME and MAP are provided: use map and set start time to TIME. "
	@echo " 2. Only TIME is provided: download ADAPT map based on TIME and set start time to TIME."
	@echo " 3. Only MAP is provided: use MAP and set the start time based on map time."
	@echo ""

######################################################################################

adapt_run_w_compile:
	@echo "Submitting AWSoM runs with a ADAPT map with re-compiling the code."
	make compile
	make rundir_local
	make run
	@echo "Finished submitting AWSoM runs with a ADAPT map."

adapt_run:
	@echo "Submitting AWSoM runs with a ADAPT map without re-compiling the code."
	make rundir_local
	make run
	@echo "Finished submitting AWSoM runs with a ADAPT map."

install:
	-@(cp ${DIR}/util/DATAREAD/srcMagnetogram/remap_magnetogram.py ${MYDIR}/Scripts/;	\
	if([ -L ${MYDIR}/Scripts/pyfits ]); then					\
		rm -f ${MYDIR}/Scripts/pyfits; 						\
	fi;										\
	ln -s ${DIR}/share/Python/pyfits ${MYDIR}/Scripts/pyfits; 			\
	)

compile:
	-@(make install;								\
	if [[ "${MODEL}" == "$(filter ${MODEL},AWSoM AWSoM2T AWSoMR AWSoMR_SOFIE)" ]]; then	\
		cd ${DIR}; 								\
		if [[ "${DOINSTALL}" == "T" ]]; then					\
			rm -f ${DIR}/bin/*.exe;						\
			./Config.pl -uninstall; 					\
			./Config.pl -install; 						\
			./Config.pl -v=Empty,SC/BATSRUS,IH/BATSRUS; 			\
		fi;									\
		if [[ "${MODEL}" == "AWSoM" ]]; then 					\
			./Config.pl -o=SC:u=Awsom,e=AwsomAnisoPi,nG=3,g=6,8,8; 		\
			./Config.pl -o=IH:u=Awsom,e=AwsomAnisoPi,nG=3,g=8,8,8; 		\
		fi;									\
		if [[ "${MODEL}" == "$(filter ${MODEL},AWSoM2T AWSoMR)" ]]; then	\
			./Config.pl -o=SC:u=Awsom,e=Awsom,nG=3,g=6,8,8;                 \
			./Config.pl -o=IH:u=Awsom,e=Awsom,nG=3,g=8,8,8;                 \
		fi; 									\
		if [[ "${MODEL}" == "AWSoMR_SOFIE" ]]; then 				\
			./Config.pl -v=SP/MFLAMPA;				\
			./Config.pl -o=SC:u=Awsom,e=AwsomSA,nG=2,g=6,8,8;             \
			./Config.pl -o=IH:u=Awsom,e=AwsomSA,nG=2,g=8,8,8;             \
			./Config.pl -o=SP:g=20000;                                      \
		fi;									\
		make -j SWMF PIDL; 							\
		cp ${DIR}/bin/SWMF.exe ${DIR}/bin/${MODEL}.exe;				\
		cd ${DIR}/util/DATAREAD/srcMagnetogram; 				\
		make HARMONICS FDIPS; 							\
	else										\
		echo "MODEL = ${MODEL}";						\
		echo "ERROR: MODEL must be either AWSoM, AWSoM2T, AWSoMR or AWSoMR_SOFIE.";	\
	fi;										\
	)

backup_run:
	-@if([ -d ${MYDIR}/${SIMDIR}/run01 ]); then					\
		rm -rf ${MYDIR}/${SIMDIR}/run_backup;					\
		mkdir -p ${MYDIR}/${SIMDIR}/run_backup;                   		\
		mv ${MYDIR}/${SIMDIR}/run[01]* ${MYDIR}/${SIMDIR}/run_backup/;          \
	fi

copy_param:
	-@(if [[ "${MODEL}" == "$(filter ${MODEL},AWSoM AWSoM2T AWSoMR AWSoMR_SOFIE)" ]]; then	\
		if [[ "${MODEL}" == "AWSoMR" ]]; then					\
			cp Param/PARAM.in.awsomr PARAM.in; 				\
		fi; 									\
		if [[ "${MODEL}" == "$(filter ${MODEL},AWSoM AWSoM2T)" ]]; then		\
			cp Param/PARAM.in.awsom PARAM.in;				\
		fi;									\
		if [[ "${MODEL}" == "AWSoMR_SOFIE" ]]; then				\
			cp Param/PARAM.in.sofie PARAM.in;				\
		fi;									\
		if [[ "${PARAM}" != "Default" ]]; then					\
			cp Param/${PARAM} PARAM.in;					\
		fi;									\
		cp Param/HARMONICS.in Param/FDIPS.in .; 				\
	else										\
		echo "MODEL = ${MODEL}";						\
		echo "ERROR: MODEL must be either AWSoM, AWSoM2T, AWSoMR or AWSoMR_SOFIE.";	\
	fi;										\
	)

clean_rundir_tmp:
	-@(cd ${MYDIR};				\
	rm -f PARAM.in HARMONICS.in FDIPS.in;	\
	rm -f map_*.out; 			\
	)

rundir_realizations:
	-@for iRealization in ${REALIZATIONLIST}; do									\
		cd ${DIR}; 												\
		make rundir MACHINE=${MACHINE} RUNDIR=${MYDIR}/${SIMDIR}/run$${iRealization}; 				\
		rm ${MYDIR}/${SIMDIR}/run$${iRealization}/SWMF.exe;			 				\
		cp ${DIR}/bin/${MODEL}.exe ${MYDIR}/${SIMDIR}/run$${iRealization}/SWMF.exe;			 	\
		cp ${MYDIR}/PARAM.in     ${MYDIR}/${SIMDIR}/run$${iRealization}; 					\
		cp ${MYDIR}/HARMONICS.in ${MYDIR}/${SIMDIR}/run$${iRealization}/SC/; 					\
		cp ${MYDIR}/FDIPS.in     ${MYDIR}/${SIMDIR}/run$${iRealization}/SC/; 					\
		cp ${MYDIR}/JobScripts/job.${PFSS}.${MACHINE} ${MYDIR}/${SIMDIR}/run$${iRealization}/job.long;		\
		mv ${MYDIR}/map_$${iRealization}.out ${MYDIR}/${SIMDIR}/run$${iRealization}/SC/;  			\
		cd ${MYDIR}/${SIMDIR}/run$${iRealization}/SC/; 								\
		if [[ "${PFSS}"  == "HARMONICS" ]]; then								\
			perl -i -p -e "s/map_1/map_$${iRealization}/g" HARMONICS.in;					\
			./HARMONICS.exe; 										\
		fi; 													\
		if [[ "${PFSS}"  == "FDIPS" ]]; then									\
			perl -i -p -e "s/map_1/map_$${iRealization}/g" FDIPS.in;					\
		fi; 													\
	done

rundir_local:
	@echo "Creating rundirs"
	make backup_run
	make copy_param
	${MYDIR}/Scripts/change_awsom_param.py --map ${MAP} -t ${TIME} -B0 ${PFSS} -p ${POYNTINGFLUX}
	make rundir_realizations
	make clean_rundir_tmp

run:
	@echo "Submitting jobs"
	-@for iRealization in ${REALIZATIONLIST}; do              	        		\
		cd ${MYDIR}/${SIMDIR}/run$${iRealization}; 					\
		if [[ "${MACHINE}" == "frontera" ]];						\
			then perl -i -p -e "s/amap01/${JOBNAME}$${iRealization}/g" job.long;  	\
			sbatch job.long;							\
		fi;										\
		if [[ "${MACHINE}" == "pfe" ]];                         			\
			then ./qsub.pfe.pbspl.pl job.long ${JOBNAME}$${iRealization};      	\
		fi; 										\
		if [[ "${MACHINE}" == "derecho" ]];						\
			then perl -i -p -e "s/amap01/${JOBNAME}$${iRealization}/g" job.long;  	\
			qsub job.long;								\
		fi;										\
	done

#########################################################################################

check_postproc:
	@if([ ! -d ${MYDIR}/Results/${RESDIR} ]); then                   			\
		rm -f error_postproc.log; 							\
		echo "Post processing simulation results to Results/${RESDIR}";			\
		mkdir -p ${MYDIR}/Results/${RESDIR}; 						\
		cp ${MYDIR}/${SIMDIR}/key_params.txt ${MYDIR}/Results/${RESDIR}/; 		\
		for RunDir in ${FullRunDirList};  do                              		\
			echo "processing rundir = $${RunDir}";					\
			cd $${RunDir};                                    			\
			if([ -f SWMF.SUCCESS ]); then                              		\
				mkdir -p ${FullResDir}/$${RunDir: -6:5};                      	\
				if([ ! -d RESULTS ]); then ./PostProc.pl -l=IH RESULTS; fi;   	\
				cp SC/map_*out ${FullResDir}/$${RunDir: -6:5}/;			\
				mv RESULTS/* ${FullResDir}/$${RunDir: -6:5}/;			\
				if [[ -f SC/fdips_bxyz.out ]]; then          			\
					mv SC/fdips_bxyz.out SC/FDIPS.in 			\
						${FullResDir}/$${RunDir: -6:5}/; 		\
				fi;								\
				if [[ -f SC/harmonics_adapt.dat ]]; then			\
					cp SC/harmonics_adapt.dat SC/HARMONICS.in 	 	\
						${FullResDir}/$${RunDir: -6:5}/ ;		\
					mv harmonics_bxyz.out ${FullResDir}/$${RunDir: -6:5}/ ; \
				fi;								\
			else									\
				echo "$${RunDir} crashed" >> ${MYDIR}/error_postproc.log;	\
			fi; 									\
		done;										\
	else                                                            			\
		echo "${RESDIR} already exists; skip post processing.";				\
	fi

#########################################################################################

check_compare:
	make check_compare_insitu
	make check_compare_remote

check_compare_insitu:
	-@(cd ${IDLDIR}; 									\
	for iRunDir in ${FullResRunDirList};  do 						\
		csh compare_insitu.sh ${DIR} $${iRunDir}/IH $${iRunDir} DEFAULT 		\
			${MYDIR}/Results/obsdata ${EVTIME} ${DTEV} ${MYDIR}/Events;		\
	done)

check_compare_insitu_py:
	-@(cd ${PYDIR};										\
	for iRunDir in ${FullResRunDirList};  do						\
		python compare_insitu.py ${DIR} $${iRunDir}/IH $${iRunDir} ${MODEL}		\
					 ${MYDIR}/Results/obsdata > $${iRunDir}/log_insitu;				\
	done)


check_compare_remote:
	-@(cd ${IDLDIR}; 									\
	for iRunDir in ${FullResRunDirList};  do 						\
		csh compare_remote.sh ${DIR} $${iRunDir}/SC $${iRunDir} ${MYDIR}/Results/obsdata; \
	done)

check_animate_xyz:
	-@(								\
	for iRunDir in ${FullResRunDirList};  do			\
		cd $${iRunDir};						\
		csh ${IDLDIR}/animate_xyz.sh;				\
	done)

clean_plot:
	@for RunDir in ${FullResRunDirList};  do 	\
		echo "cleaning $${RunDir}";		\
		cd $${RunDir}; 				\
		rm -f *eps; 				\
		rm -f log_insitu log_remote; 		\
	done

#########################################################################################

check_postproc_all:
	@for iSimDir in ${SimDirList}; do					\
		make check_postproc RESDIR=$${iSimDir} SIMDIR=$${iSimDir};	\
	done

check_compare_insitu_all:
	-@(cd ${IDLDIR}; 								\
	for iResDir in ${FullResDirList}; do						\
		csh compare_insitu.sh ${DIR} $${iResDir} $${iResDir} DEFAULT 		\
			${MYDIR}/Results/obsdata ${EVTIME} ${DTEV} ${MYDIR}/Events;	\
	done)

check_compare_remote_all:
	@for iResDir in ${ResDirList};  do 				\
		make check_compare_remote RESDIR=$${iResDir};		\
	done

check_animate_xyz_all:
	@for iResDir in ${ResDirList};  do				\
		make check_animate_xyz RESDIR=$${iResDir};		\
	done

clean_plot_all:
	@(for iResDir in ${ResDirList};  do 				\
		make clean_plot RESDIR=$${iResDir};			\
	done;								\
	for iResDir in ${FullResDirList}; do				\
		echo "cleaning $${iResDir}"; 				\
		cd $${iResDir}; 					\
		rm -f *eps log_insitu log_remote; 			\
	done)


#########################################################################################
