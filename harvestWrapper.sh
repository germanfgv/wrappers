#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This script creates a Express job configuration file"
   echo "that can later be executed using cmsRun."
   echo
   echo "Syntax: harvestWrapper.sh [-r|j|h]"
   echo "options:"
   echo "-r    User provides the run number and stream name."
   echo "      Creates an Express configuration that mimicks"
   echo "      the one used in product."
   echo "      usage: harvestWrapper.sh -r <run_number> <primary_dataset> lfn"
   echo ""
   echo "-j    User provides a JSON file containing the"
   echo "      desired configuration, i. e. GT, scenario, etc"
   echo "      Visit this url foran example JSON: https://cmsweb.cern.ch/t0wmadatasvc/prod/reco_config?run=322963&primary_dataset=ZeroBias"
   echo "      usage: harvestWrapper.sh -j <path_to_json> lfn"
   echo ""
   echo "-h    Prints this help message"
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################


# Get the options
json_filename="config.json"
while getopts ":hjr:" option; do
    case $option in
        r) # Get JSON from t0WMADataSvc
            if [ "$#" -ne 4 ]; then
                echo "Illegal number of parameters.";
                Help
                exit
            fi
            run_num=$2; pd=$3; lfn=$4
            curl "https://cmsweb.cern.ch/t0wmadatasvc/prod/reco_config?run=$run_num&primary_dataset=$pd_name" > $json_filename;;
        j) # User provided JSON
            if [ "$#" -ne 3 ]; then
                echo "Illegal number of parameters.";
                Help;
                exit;
            fi
            json_filename=$2; lfn=$3;; 
        h) # display Help
            Help
            exit;;
        \?) # Invalid option
            echo "Error: Invalid option"
            Help
            exit;;
   esac
done

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

python $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunDQMHarvesting.py --scenario=$scenarioj --global-tag $globaltagj --lfn=$lfn --run=$runnum --dataset=$datanam --dqmio
echo If you want to use cmsRun -j FrameworkJobReport.xml RunDQMHarvestingCfg.py then you should move to the following folder and make sure that the file is actually present in the local storage. Otherwise cmsRun will fail.
pwd
eval `scramv1 runtime -sh`
