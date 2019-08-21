#!/bin/bash

echo This wrapper works by creating a new project area, so it should be used on a local lxplus area. If you already have a project area on the folder then this wrapper will not work

    echo Please provide the run number i.e. 323940
    read runnum
    echo Please provide the dataset name i.e. ZeroBias
    read datanam
    echo Please provide the LFN i.e. /store/whatever
    read lfn

curl "https://cmsweb.cern.ch/t0wmadatasvc/prod/reco_config?run=$runnum&primary_dataset=$datanam" > any.json
scramarchj=`cat any.json | jq -r '.result[].scram_arch'`
cmsswj=`cat any.json | jq -r '.result[].cmssw'`
scenarioj=`cat any.json | jq -r '.result[].scenario'`
globaltagj=`cat any.json | jq -r '.result[].global_tag'`
alcaskimj=`cat any.json | jq -r '.result[].alca_skim'`
alcaskim=${alcaskimj[@]//,/+}
physkimj=`cat any.json | jq -r '.result[].physics_skim'`
physkim=${physkimj[@]//,/+}
nthread=`cat any.json | jq -r '.result[].multicore'`
echo $scramarchj $cmsswj $scenarioj $globaltagj $alcaskimj $physkimi $nthread
rm any.json
#source cmsset values
source /cvmfs/cms.cern.ch/cmsset_default.sh

# define architecture as requested by user
SCRAM_ARCH=$scramarchj; export SCRAM_ARCH

#create the project with CMSSW version given by the user
scramv1 project CMSSW $cmsswj
cd $cmsswj/src/

#source cms environment variables
eval `scramv1 runtime -sh`

echo Is $cmsswj a CMSSW version superior to 11_0_0_pre1? Answer Y or N
read varnam2
if [ $varnam2 == 'Y' ]
then
    if [[$alcaskim == 'null' && $physkim == 'null' ]]
    then
    python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --dqmio --global-tag $globaltagj --nThreads=nthread --lfn=$lfn
    else
        if [ $alcaskim == 'null' ]
        then
        python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --dqmio --global-tag $globaltagj --nThreads=nthread --lfn=$lfn --PhysicsSkims=$physkim
        else
        if [ $physkim = 'null' ]
        then
        python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --dqmio --global-tag $globaltagj --nThreads=nthread --lfn=$lfn --alcarecos=$alcaskim
        else
        python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --dqmio --global-tag $globaltagj --nThreads=nthread --lfn=$lfn --alcarecos=$alcaskim --PhysicsSkims=$physkim
        fi
        fi
    fi

else
 if [[ $alcaskim == 'null' && $physkim == 'null' ]]
    then
    python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --dqmio --global-tag $globaltagj --lfn=$lfn
    else
        if [ $alcaskim == 'null' ]
        then
        python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --dqmio --global-tag $globaltagj  --lfn=$lfn --PhysicsSkims=$physkim
        else
            if [ $physkim = 'null' ]
            then
            python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --dqmio --global-tag $globaltagj --lfn=$lfn --alcarecos=$alcaskim
            else
            python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --dqmio --global-tag $globaltagj --lfn=$lfn --alcarecos=$alcaskim --PhysicsSkims=$physkim
            fi
        fi
    fi
fi
echo If you want to use cmsRun -e RunPromptRecoCfg.py then you should move to the following folder
pwd
eval `scramv1 runtime -sh`
