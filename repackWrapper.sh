#!/bin/bash
 
echo This REPACK wrapper works by creating a new project area, so it should be used on a local lxplus area. If you already have a project area on the folder then this wrapper will not work
echo Please provide the run number i.e. 326607
read runnum
echo Please provide the LFN i.e. /store/whatever
read lfn

curl "https://cmsweb.cern.ch/t0wmadatasvc/prod/express_config?run=$runnum" > any5.json
scramarchj=`cat any5.json | jq -r '.result[].scram_arch'`
cmsswj=`cat any5.json | jq -r '.result[].cmssw'`
scenarioj=`cat any5.json | jq -r '.result[].scenario'`
globaltagj=`cat any5.json | jq -r '.result[].global_tag'`
alcaskimj=`cat any5.json | jq -r '.result[].alca_skim'`
alcaskim=${alcaskimj[@]//,/+}
physkim=`cat any5.json | jq -r '.result[].physics_skim'`
nthread=`cat any5.json | jq -r '.result[].multicore'`
echo $scramarchj $cmsswj $scenarioj $globaltagj $alcaskimj $physkimi $nthread
rm any5.json
#source cmsset values
source /cvmfs/cms.cern.ch/cmsset_default.sh

# define architecture as requested by user
SCRAM_ARCH=$scramarchj; export SCRAM_ARCH
 
#create the project with CMSSW version given by the user
scramv1 project CMSSW $cmsswj
cd $cmsswj/src/

#source cms environment variables
eval `scramv1 runtime -sh`
python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunRepack.py --select-events HLT:path1,HLT:path2 --lfn=$lfn
echo If you want to do cmsRun -e RunRepackCfg.py then you should move to the following folder 
pwd
eval `scramv1 runtime -sh`
