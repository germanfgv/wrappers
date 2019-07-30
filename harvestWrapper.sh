#!/bin/bash

echo This HARVEST wrapper works by creating a new project area, so it should be used on a local lxplus area. If you already have a project area on the folder then this wrapper will not work. If you want to obtain run number and dataset from an LFN, please use DAS.
echo Please remember to have your name, email and github user configured. If you do not, then use the following commands to do it.
echo git config --global user.name "First name Last name"
echo git config --global user.email "<Your-Email-Address>"
echo git config --global user.github "<Your-GitHub-Account-Username>"
echo Do you have a github account linked with this session and a forked copy of cmssw master branch? Answer Y or N
read varnam1
if [ $varnam1 == 'Y' ]
then
    echo Please provide the run number i.e. 321295
    read runnum
    echo Please provide the full dataset name i.e. /ZeroBias/Run2018D-PromptReco-v2/DQMIO
    read datanam
    echo Please provide the LFN i.e. /store/whatever. For this wrapper you will need to provide an lfn of a file located at CERN, or you will need to get the file on your local machine by using xrootd or by requesting the transfer from tape. If you have the file in your local area then write the input as follows: file:PFN i.e. file:/afs/cern.ch/user/f/fiori/public/Andres/9F411A2F-9C94-D54F-894B-83D60BF55C41.root
    read lfn
else
    echo Please configure your github account with this lxplus session and make a forked copy of cmssw repository
    exit 0
fi

datanam2=$(echo $datanam| cut -d'/' -f 2)
curl "https://cmsweb.cern.ch/t0wmadatasvc/prod/reco_config?run=$runnum&primary_dataset=$datanam2" > any2.json
scramarchj=`cat any2.json | jq -r '.result[].scram_arch'`
cmsswj=`cat any2.json | jq -r '.result[].cmssw'`
scenarioj=`cat any2.json | jq -r '.result[].scenario'`
globaltagj=`cat any2.json | jq -r '.result[].global_tag'`
echo $scramarchj $cmsswj $scenarioj $globaltagj
rm any2.json
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

# runs Harvest
eval `scramv1 runtime -sh`
python RunDQMHarvesting.py --scenario=$scenarioj --global-tag $globaltagj --lfn=$lfn --run=$runnum --dataset=$datanam --dqmio
echo If you want to use cmsRun -j FrameworkJobReport.xml RunDQMHarvestingCfg.py then you should move to the following folder and make sure that the file is actually present in the local storage. Otherwise cmsRun will fail.
pwd
eval `scramv1 runtime -sh`
