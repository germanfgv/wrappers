#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This script creates a Repack job configuration file"
   echo "that can later be executed using cmsRun."
   echo
   echo "Syntax: repackWrapper.sh [-r|j|h]"
   echo "options:"
   echo "-r    User provides the run number and stream name."
   echo "      Creates a Repack configuration that mimicks"
   echo "      the one used in product."
   echo "      usage: repackWrapper.sh -r <run_number> lfn"
   echo ""
   echo "-j    User provides a JSON file containing the"
   echo "      desired configuration, i. e. GT, scenario, etc"
   echo "      Visit this url foran example JSON: https://cmsweb.cern.ch/t0wmadatasvc/prod/express_config?run=322963&stream=Calibration"
   echo "      usage: repackWrapper.sh -j <path_to_json> lfn"
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
while getopts ":hrj:" option; do
    case $option in
        r) # Get JSON from t0WMADataSvc
            if [ "$#" -ne 3 ]; then
                echo "Illegal number of parameters.";
                Help
                exit
            fi
            run_num=$2; lfn=$3
            curl "https://cmsweb.cern.ch/t0wmadatasvc/prod/express_config?run=$run_num" > $json_filename;;
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


scramarchj=`cat $json_filename | jq -r '.result[0].scram_arch'`
cmsswj=`cat $json_filename | jq -r '.result[0].cmssw'`
scenarioj=`cat $json_filename | jq -r '.result[0].scenario'`
globaltagj=`cat $json_filename | jq -r '.result[0].global_tag'`
alcaskimj=`cat $json_filename | jq -r '.result[0].alca_skim'`
alcaskim=${alcaskimj[@]//,/+}
physkim=`cat $json_filename | jq -r '.result[0].physics_skim'`
nthread=`cat $json_filename | jq -r '.result[0].multicore'`

echo $scramarchj $cmsswj $scenarioj $globaltagj $alcaskimj $physkimi $nthread

#source cmsset values
source /cvmfs/cms.cern.ch/cmsset_default.sh

# define architecture as requested by user
SCRAM_ARCH=$scramarchj; export SCRAM_ARCH

#create the project with CMSSW version given by the user
scramv1 project CMSSW $cmsswj
cd $cmsswj/src/

#source cms environment variables
eval `scramv1 runtime -sh`

echo CMSSW $cmsswj
if [[ $cmsswj > "CMSSW_12_" ]]
then
    echo "Using Python3 CMSSW version"
    command="python3"
else
    echo "Using Python2 CMSSW version"
    command="python"
fi

echo $command $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunRepack.py --lfn=$lfn

$command $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunRepack.py --lfn=$lfn
echo If you want to do cmsRun -e RunRepackCfg.py then you should move to the following folder 
pwd
eval `scramv1 runtime -sh`
