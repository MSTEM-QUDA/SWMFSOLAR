SHELL=/bin/bash

include ../Makefile.def

MYDIR       = ${DIR}/SWMFSOLAR/
QUEDIR      = $(MYDIR)

TIME = 2012,03,12,08,00

REALIZATIONS = 01,02,03,04,05,06,07,08,09,10,11,12

POYNTINGFLUX = 1.0e6

START_TIME       = $(shell echo ${TIME} | tr , ' ')
REALIZATIONLIST  = $(shell echo ${REALIZATIONS} | tr , ' ')


help : 
	@echo "make the AWSoM or AWSoM-R run with a ADAPT map"

######################################################################################
awsom_adapt_harmonics:
	@echo "Submitting AWSoM runs with a ADAPT map."
	make awsom_compile
	make awsom_rundir
	make awsom_run_harmonics
	@echo "Finished submitting AWSoM runs with a ADAPT map."

awsom_adapt_fdips:
	@echo "Submitting AWSoM runs with a ADAPT map."
	make awsom_compile
	make awsom_rundir
	make awsom_run_fdips
	@echo "Finished submitting AWSoM runs with a ADAPT map."

awsom_compile:
	-@(cd ${DIR}; \
	./Config.pl -v=Empty,SC/BATSRUS,IH/BATSRUS; \
	./Config.pl -o=SC:u=AwsomFluids,e=MhdWavesPeAnisoPi,nG=3; \
	./Config.pl -o=IH:u=AwsomFluids,e=MhdWavesPeAnisoPiSignB,nG=3; \
	./Config.pl -g=SC:6,8,8,IH:8,8,8; \
	make -j SWMF PIDL; \
	cd ${DIR}/util/DATAREAD/srcMagnetogram; \
	make HARMONICS FDIPS; \
	cp ${DIR}/util/DATAREAD/srcMagnetogram/remap_magnetogram.py ${MYDIR}/Scripts/;	\
	if([ ! -L ${MYDIR}/Scripts/swmfpy ]); then					\
		ln -s ${DIR}/share/Python/swmfpy/swmfpy ${MYDIR}/Scripts/swmfpy; 	\
	fi;										\
	)

awsom_rundir:
	@echo "Creating rundirs"
	if([ -d ${MYDIR}/run01 ]); then                         \
		rm -rf ${MYDIR}/run_backup;                     \
		mkdir -p ${MYDIR}/run_backup;                   \
		mv run[01]* ${MYDIR}/run_backup/;               \
	fi;							\
	cp PARAM/PARAM.in.awsom PARAM.in
	Scripts/change_param.py -t ${START_TIME} -p ${POYNTINGFLUX}
	for iRealization in ${REALIZATIONLIST}; do					\
		cd $(DIR); 								\
		make rundir RUNDIR=${MYDIR}/run$${iRealization}; 			\
		cp ${MYDIR}/PARAM.in ${MYDIR}/run$${iRealization}; 			\
		mv ${MYDIR}/map_$${iRealization}.out ${MYDIR}/run$${iRealization}/SC/;  \
	done
	rm PARAM.in

awsom_run_harmonics:
	@echo "Submitting jobs"
	for iRealization in ${REALIZATIONLIST}; do              	        	\
		cp ${MYDIR}/PARAM/HARMONICS.in ${MYDIR}/run$${iRealization}/SC/; 	\
		cd ${MYDIR}/run$${iRealization}/SC/; 					\
		sed -i '' "s/map_1/map_$${iRealization}/g" HARMONICS.in; 		\
		HARMONICS.exe; 								\
		mv harmonics_adapt.dat ${MYDIR}/run$${iRealization};			\
	done


#########################################################################################

awsomr_adapt_harmonics:
	@echo "Submitting AWSoM-R runs with a ADAPT map."
	make awsomr_compile
	make awsomr_rundir
	make awsomr_run_harmonics
	@echo "Finished submitting AWSoM-R runs with a ADAPT map."

awsomr_adapt_fdips:
	@echo "Submitting AWSoM-R runs with a ADAPT map."
	make awsomr_compile
	make awsomr_rundir
	make awsomr_run_fdips
	@echo "Finished submitting AWSoM-R runs with a ADAPT map."


awsomr_compile:
	-@(cd ${DIR}; \
	./Config.pl -v=Empty,SC/BATSRUS,IH/BATSRUS; \
	./Config.pl -o=SC:u=ScChromo,e=MhdWavesPeAnisoPi,nG=3; \
	./Config.pl -o=IH:u=ScChromo,e=MhdWavesPeAnisoPiSignB,nG=3; \
	./Config.pl -g=SC:6,8,8,IH:8,8,8; \
	make -j SWMF PIDL; \
	cd ${DIR}/util/DATAREAD/srcMagnetogram; \
	make HARMONICS FDIPS; \
	cp ${DIR}/util/DATAREAD/srcMagnetogram/remap_magnetogram.py ${MYDIR}/Scripts/;	\
	if([ ! -L ${MYDIR}/Scripts/swmfpy ]); then					\
		ln -s ${DIR}/share/Python/swmfpy/swmfpy ${MYDIR}/Scripts/swmfpy; 	\
	fi;										\
	)

awsomr_rundir:
	@echo "Creating rundirs"
	if([ -d ${MYDIR}/run01 ]); then                         \
		rm -rf ${MYDIR}/run_backup;                     \
		mkdir -p ${MYDIR}/run_backup;                   \
		mv run[01]* ${MYDIR}/run_backup/;               \
	fi;							\
	cp PARAM/PARAM.in.awsomr PARAM.in
	Scripts/change_param.py -t ${START_TIME} -p ${POYNTINGFLUX}
	for iRealization in ${REALIZATIONLIST}; do					\
		cd $(DIR); 								\
		make rundir RUNDIR=${MYDIR}/run$${iRealization}; 			\
		cp ${MYDIR}/PARAM.in ${MYDIR}/run$${iRealization}; 			\
		mv ${MYDIR}/map_$${iRealization}.out ${MYDIR}/run$${iRealization}/SC/;  \
	done
	rm PARAM.in

awsomr_run_harmonics:
	@echo "Submitting jobs"
	for iRealization in ${REALIZATIONLIST}; do              	        	\
		cp ${MYDIR}/PARAM/HARMONICS.in ${MYDIR}/run$${iRealization}/SC/; 	\
		cd ${MYDIR}/run$${iRealization}/SC/; 					\
		sed -i '' "s/map_1/map_$${iRealization}/g" HARMONICS.in; 		\
		HARMONICS.exe; 								\
		mv harmonics_adapt.dat ${MYDIR}/run$${iRealization};			\
	done
