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

anabuild=ana.416

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $2 > inputfiles.list
    echo $3 >> inputfiles.list
    getinputfiles.pl --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
	echo error from getinputfiles.pl  --filelist inputfiles.list, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    exit -1
fi
# arguments 
# $1: number of events
# $2: mbd g4hits input file
# $3: truth g4hits input file
# $4: output file
# $5: output dir
# $6: run number
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(mbd g4hits file\): $2
echo arg3 \(truth g4hits file\): $3
echo arg4 \(output file\): $4
echo arg5 \(output dir\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $6)
sequence=$(printf "%06d" $7)

filename=timing

echo running root.exe -q -b Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$cdbtag\"\)
root.exe -q -b  Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$cdbtag\"\)

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/ampt/pass3_mbdepd/timing.run${6}

[ ! -d $timedirname ] && mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename


echo "script done"
