#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This script creates a Reco job configuration file"
   echo "that can later be executed using cmsRun."
   echo
   echo "Syntax: recoWrapper.sh [-r|j|h]"
   echo "options:"
   echo "-r    User provides the run number and stream name."
   echo "      Creates an Reco configuration that mimicks"
   echo "      the one used in product."
   echo "      usage: recoWrapper.sh -r <run_number> <primary_dataset> lfn"
   echo ""
   echo "-j    User provides a JSON file containing the"
   echo "      desired configuration, i. e. GT, scenario, etc"
   echo "      Visit this url foran example JSON: https://cmsweb.cern.ch/t0wmadatasvc/prod/reco_config?run=322963&primary_dataset=Calibration"
   echo "      usage: recoWrapper.sh -j <path_to_json> lfn"
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
            run_num=$2; dataset_name=$3; lfn=$4
            curl "https://cmsweb.cern.ch/t0wmadatasvc/prod/reco_config?run=$run_num&primary_dataset=$dataset_name" > $json_filename;;
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

scramarchj=`cat $json_filename | jq -r '.result[].scram_arch'`
cmsswj=`cat $json_filename | jq -r '.result[].cmssw'`
scenarioj=`cat $json_filename | jq -r '.result[].scenario'`
globaltagj=`cat $json_filename | jq -r '.result[].global_tag'`
alcaskimj=`cat $json_filename | jq -r '.result[].alca_skim'`
alcaskim=${alcaskimj[@]//,/+}
physkimj=`cat $json_filename | jq -r '.result[].physics_skim'`
dqmseqj=`cat $json_filename | jq -r '.result[].dqm_seq'`
dqmseq=${dqmseqj[@]//,/+}
physkim=${physkimj[@]//,/+}
nthread=`cat $json_filename | jq -r '.result[].multicore'`
echo $scramarchj $cmsswj $scenarioj $globaltagj $alcaskimj $physkimi $nthread $dqmseqj

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

if [[ $cmsswj > "CMSSW_11_" && $cmsswj < "CMSSW_13_3_" ]]
then
    echo "Using nThreads"
    options="--nThreads=$nthread"
else
    options=""
fi

if [ $alcaskim != 'null' ]
then
    
    options="$options --alcarecos=$alcaskim"
fi

if [ $physkim != 'null' ]
then
    
    options="$options --PhysicsSkims=$physkim"
fi

if [ $dqmseq != 'null' ]
then
    
    options="$options --dqmio --dqmSeq=$dqmseq"
else
    options="$options --dqmio"
fi

echo "$command $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --global-tag $globaltagj --lfn=$lfn $options"
$command $CMSSW_RELEASE_BASE/src/Configuration/DataProcessing/test/RunPromptReco.py --scenario=$scenarioj --reco --aod --miniaod --global-tag $globaltagj --lfn=$lfn $options

echo If you want to use cmsRun -e RunPromptRecoCfg.py then you should move to the following folder
pwd
eval `scramv1 runtime -sh`
