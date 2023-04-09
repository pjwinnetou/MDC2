#!/usr/bin/bash

export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

hostname

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir
echo running: $this_script $*

ana_calo=ana.349
ana_global=ana.354
ana_pass3trk=ana.349

# just to get a working environment, the specific ana builds for each reconstruction are set later
source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: g4hits input file
# $3: calo output file
# $4: calo output dir
# $5: global output file
# $6: global output dir
# $7: track output dir
# $8: jettrigger
# $9: runnumber
# $10: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(g4hits file\): $2
echo arg3 \(calo output file\): $3
echo arg4 \(calo output dir\): $4
echo arg5 \(global output file\): $5
echo arg6 \(global output dir\): $6
echo arg7 \(trk output dir\): $7
echo arg8 \(jettrigger\): $8
echo arg9 \(runnumber\): $9
echo arg10 \(sequence\): ${10}

runnumber=$(printf "%010d" $9)
sequence=$(printf "%05d" ${10})
filename_calo=js_pp200_signal_pass2_nopileup_calo_$8
filename_epd=js_pp200_signal_pass2_nopileup_epd_$8
filename_trkr=js_pp200_signal_pass2_nopileup_trkr_$8

rsyncdirname=/sphenix/user/sphnxpro/prmon/js_pp200_signal/pass2_nopileup/run$9/$8
[ -d $rsyncdirname ] || mkdir -p $rsyncdirname

#---------------------------------------------------------------
# Calorimeter Reconstruction
source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_calo

echo 'here comes your Calorimeter Reconstruction environment'
printenv

txtfilename=${filename_calo}-${runnumber}-${sequence}.txt
jsonfilename=${filename_calo}-${runnumber}-${sequence}.json

echo running prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)
#prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)

[ -f $txtfilename ] && rsync -av $txtfilename $rsyncdirname
[ -f $jsonfilename ] && rsync -av $jsonfilename $rsyncdirname

#---------------------------------------------------------------
# Global Reconstruction
source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_global

echo 'here comes your Global Reconstruction environment'
printenv

txtfilename=${filename_epd}-${runnumber}-${sequence}.txt
jsonfilename=${filename_epd}-${runnumber}-${sequence}.json

echo running prmon --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Global.C\($1,\"$2\",\"$5\",\"$6\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Global.C\($1,\"$2\",\"$5\",\"$6\"\)

[ -f $txtfilename ] && rsync -av $txtfilename $rsyncdirname
[ -f $jsonfilename ] && rsync -av $jsonfilename $rsyncdirname

#---------------------------------------------------------------
# pass3 tracking
source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_pass3trk

echo 'here comes your Pass3 Tracking environment'
printenv

txtfilename=${filename_trkr}-${runnumber}-${sequence}.txt
jsonfilename=${filename_trkr}-${runnumber}-${sequence}.json

echo running prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$7\",\"$8\"\)
#prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$7\",\"$8\"\)

[ -f $txtfilename ] && rsync -av $txtfilename $rsyncdirname
[ -f $jsonfilename ] && rsync -av $jsonfilename $rsyncdirname

echo "script done"
