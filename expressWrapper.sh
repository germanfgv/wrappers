#!/bin/bash

echo This EXPRESS wrapper works by creating a new project area, so it should be used on a local lxplus area. If you already have a project area on the folder then this wrapper will not work
echo Please remember to have your name, email and github user configured. If you do not, then use the following commands to do it.
echo git config --global user.name "First name Last name"
echo git config --global user.email "<Your-Email-Address>"
echo git config --global user.github "<Your-GitHub-Account-Username>"
echo Do you have a github account linked with this session and a forked copy of cmssw master branch? Answer Y or N
read varnam1
if [ $varnam1 == 'Y' ]
then
    echo Please provide the run number i.e. 326607
    read runnum
    curl "https://cmsweb.cern.ch/t0wmadatasvc/prod/express_config?run=$runnum" > any4.json
    echo The following Streams were Express processed for your selected Run:
    echo `cat any4.json | jq -r '.result[].stream'`
    rm -rf any4.json
    echo Please provide the stream name i.e. Calibration
    read streamnam
    echo Please provide the LFN i.e. /store/whatever
    read lfn
else
    echo Please configure your github account with this lxplus session and make a forked copy of cmssw repository
    exit 0
fi

curl "https://cmsweb.cern.ch/t0wmadatasvc/prod/express_config?run=$runnum&stream=$streamnam" > any3.json
scramarchj=`cat any3.json | jq -r '.result[].scram_arch'`
cmsswj=`cat any3.json | jq -r '.result[].cmssw'`
scenarioj=`cat any3.json | jq -r '.result[].scenario'`
globaltagj=`cat any3.json | jq -r '.result[].global_tag'`
alcaskimj=`cat any3.json | jq -r '.result[].alca_skim'`
alcaskim=${alcaskimj[@]//,/+}
physkim=`cat any3.json | jq -r '.result[].physics_skim'`
nthread=`cat any3.json | jq -r '.result[].multicore'`
echo $scramarchj $cmsswj $scenarioj $globaltagj $alcaskimj $physkimi $nthread
rm any3.json
#source cmsset values
source /cvmfs/cms.cern.ch/cmsset_default.sh

# define architecture as requested by user
SCRAM_ARCH=$scramarchj; export SCRAM_ARCH
#create the project with CMSSW version given by the user
scramv1 project CMSSW $cmsswj
cd $cmsswj/src/

#source cms environment variables
eval `scramv1 runtime -sh`

#add package of data processing
# check if this can be configured to include another version
git cms-addpkg Configuration/DataProcessing

#create the project
scram b
cd Configuration/DataProcessing/test

# runs promptreco
eval `scramv1 runtime -sh`
echo Is $cmsswj a CMSSW version superior to 11_0_0_pre1? Answer Y or N
read varnam2
#TODO insert if statements to check if there are alcarecos or not.
if [ $varnam2 == 'Y' ]
then
    if [ $alcaskim == 'null' ]
    then
        python RunExpressProcessing.py --scenario=$scenarioj --raw --reco --fevt --dqm --global-tag $globaltagj --lfn=$lfn --nThreads=nthread
    else
        python RunExpressProcessing.py --scenario=$scenarioj --raw --reco --fevt --dqm --global-tag $globaltagj --lfn=$lfn --nThreads=nthread --alcarecos=$alcaskim
    fi
else
    if [ $alcaskim == 'null' ]
    then
        python RunExpressProcessing.py --scenario=$scenarioj --raw --reco --fevt --dqm --global-tag $globaltagj --lfn=$lfn
    else
        python RunExpressProcessing.py --scenario=$scenarioj --raw --reco --fevt --dqm --global-tag $globaltagj --lfn=$lfn --alcarecos=$alcaskim
    fi
fi
echo If you want to do cmsRun -e RunExpressProcessingCfg.py then you should move to the following folder
pwd
eval `scramv1 runtime -sh`