
#!/bin/bash
############################################################
# T0 API lib                                               #
############################################################
#
# This set of functions simplify access to T0 API Endpoints
# to be used in T0 Wrapper scripts. This library requires 
# that X509 env variables point to a valid proxy or cert/key
#
# All queries to API are persisted in a file with path T0_API_JSON_FILENAME


declare -A configMap
if [ -z "${T0_API_JSON_FILENAME}"];then
    T0_API_JSON_FILENAME="config.json"
fi
T0_API_BASE_URL="https://cmsweb.cern.ch/t0wmadatasvc/prod/"

#######################################
# Get credentials from X509 env variables
# Globals:
#   X509_USER_PROXY, X509_USER_KEY, 
#   X509_USER_CERT
# Arguments:
#   None
# Outputs:
#   Writes credentials for curl. Proxy if 
#   possible, cert+key otherwise
#######################################
get_credentials() {
    if [ ! -z "${X509_USER_PROXY}" ]; then
        echo "--proxy ${X509_USER_PROXY}"
    elif [ ! -z "${X509_USER_KEY}" -a ! -z "${X509_USER_CERT}" ]; then
        echo "--cert ${X509_USER_CERT} --key ${X509_USER_KEY}"
    fi
}

curl_request() {

    creds="$(get_credentials)"
    if [ -z "${creds}" ]; then
        echo "No credentials found"
        return -1
    fi
    url=$1
    if [ -z "${url}" ]; then
        echo "No URL"
        return -1
    fi

    echo $url
    curl $creds -k "$url" > $T0_API_JSON_FILENAME
}


#######################################
# Get express configuration for all streams of the
# latest run. Parameters can specify a runnumber and
# stream
# Globals:
#   X509_USER_PROXY, X509_USER_KEY, 
#   X509_USER_CERT, T0_API_JSON_FILENAME
# Arguments:
#   Runnumber (optional)
#   Stream (optional)
# Outputs:
#   Writes express configuration into T0_API_JSON_FILENAME
#######################################
get_express_config() {

    url="${T0_API_BASE_URL}express_config"
    # Check runnumber exist
    if [ ! -z "${1}" ]; then
        url="${url}?run=${1}"
    fi
    # Check if stream parameter exist
    if [ ! -z "${2}" ]; then
        url="${url}&stream=${2}"
    fi

    curl_request "$url"
}

#######################################
# Get reco configuration for all PDs of the
# latest run. Parameters can specify a runnumber and
# PD
# Globals:
#   X509_USER_PROXY, X509_USER_KEY, 
#   X509_USER_CERT, T0_API_JSON_FILENAME
# Arguments:
#   Runnumber (optional)
#   primary_dataset (optional)
# Outputs:
#   Writes express configuration into T0_API_JSON_FILENAME
#######################################
get_reco_config() {

    url="${T0_API_BASE_URL}reco_config"
    # Check runnumber exist
    if [ ! -z "${1}" ]; then
        url="${url}?run=${1}"
    fi
    # Check if stream parameter exist
    if [ ! -z "${2}" ]; then
        url="${url}&primary_dataset=${2}"
    fi

    curl_request "$url"
}

#######################################
# Load repack config from json file
# 
# Globals:
# Arguments:
#   path_to_json (optional)
# Outputs:
#   Populates global variable configMap
#######################################
load_repack_config() {
    if [ ! -z "${1}" ]; then
        T0_API_JSON_FILENAME="${1}"
    fi
    configMap['scram_arch']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].scram_arch'`
    configMap['cmssw']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].cmssw'`

}

#######################################
# Load express config from json file
# 
# Globals:
# Arguments:
#   path_to_json (optional)
# Outputs:
#   Populates global variable configMap
#######################################
load_express_config() {
    if [ ! -z "${1}" ]; then
        T0_API_JSON_FILENAME="${1}"
    fi
    configMap['scram_arch']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].scram_arch'`
    configMap['cmssw']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].cmssw'`
    configMap['reco_scram_arch']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].reco_scram_arch'`
    configMap['reco_cmssw']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].reco_cmssw'`
    configMap['scenario']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].scenario'`
    configMap['global_tag']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].global_tag'`
    configMap['alca_skim']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].alca_skim' | sed -e 's/,/+/g'`
    configMap['physics_skim']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].physics_skim' | sed -e 's/,/+/g'`
    configMap['dqm_seq']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].dqm_seq' | sed -e 's/,/+/g'`
    configMap['multicore']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].multicore'`

}

#######################################
# Load reco config from json file
# 
# Globals:
# Arguments:
#   path_to_json (optional)
# Outputs:
#   Populates global variable configMap
#######################################
load_reco_config() {
    if [ ! -z "${1}" ]; then
        T0_API_JSON_FILENAME="${1}"
    fi
    configMap['reco_scram_arch']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].scram_arch'`
    configMap['reco_cmssw']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].cmssw'`
    configMap['scenario']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].scenario'`
    configMap['global_tag']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].global_tag'`
    configMap['alca_skim']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].alca_skim' | sed -e 's/,/+/g'`
    configMap['physics_skim']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].physics_skim' | sed -e 's/,/+/g'`
    configMap['dqm_seq']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].dqm_seq' | sed -e 's/,/+/g'`
    configMap['multicore']=`cat $T0_API_JSON_FILENAME | jq -r '.result[0].multicore'`

}
