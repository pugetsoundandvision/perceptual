#!/usr/bin/env bash
SCRIPTNAME=$(basename "${0}")
SCRIPTDIR=$(dirname "${0}")

. "${SCRIPTDIR}/mmfunctions" || { echo "Missing '${SCRIPTDIR}/mmfunctions'. Exiting." ; exit 1 ;};
. "${SCRIPTDIR}/FINGERPRINTDB_CONFIG.txt" || { echo "Missing '${SCRIPTDIR}/FINGERPRINTDB_CONFIG.txt'. Exiting." ; exit 1 ;};

_usage(){
cat << EOF;
Takes an input file, calculates a video fingerprint for specified portion, and compares results to fingerprint database
Usage: "${SCRIPTNAME}" [ -h ] [ -i ] [ -o ] [ -t ] inputfile1 | inputfile2
-h Display this help
-i Set input time in seconds for fingerprint comparison
-o Set output time in seconds for fingerprint comparison
-t Text only results (disables preview window)
EOF
exit
}

OPTIND=1
while getopts "hi:o:t" OPT ; do
    case "${OPT}" in
        i) INTIME="${OPTARG}" ;;
        o) OUTTIME="${OPTARG}" ;;
        h) _usage ;;
        t) MODE="text" ;;
        *) echo "bad option -${OPTARG}" ; _usage ;;
    esac
done
shift $(( ${OPTIND} - 1 ))

if ! [ "${1}" ] ; then
    _usage
fi

while [ "${*}" != "" ] ; do
    #Set up input and temp files
    INPUT="${1}"
    shift

    #Confirm input is a video file
    if [[ "$(uname -s)" = Darwin ]] ; then
        VIDEOCHECK='file -Ib'
    elif [[ "$(uname -s)" = Linux ]] ; then
        VIDEOCHECK='file -i'
    fi
    if ! [[ -z ${VIDEOCHECK} ]] ; then
        if [[ -z $(${VIDEOCHECK} "${INPUT}" | grep video) ]] ; then
            echo "Input is not a video file" && continue
        fi
    fi

    IO=$(mktemp)
    TEMPFINGERPRINT=$(mktemp)
    TEMPFINGERPRINT_SORTED=$(mktemp)
    RESULTS=$(mktemp)
    VISUALRESULTS=$(mktemp)
    DRAWTEXT=$(mktemp)
    #Set up concat input for fingerprint filter
    echo "file '${INPUT}'" > "${IO}"

    if [ -n "${INTIME}" ] ; then
        if ! [[ "${INTIME}" =~ ^-?[0-9]+$ ]] ; then
            echo 'Please use an integer value for input time' && exit 0
        else
            echo "inpoint ${INTIME}" >> "${IO}"
        fi
    fi

    if [ -n "${OUTTIME}" ]; then
        if ! [[ "${OUTTIME}" =~ ^-?[0-9]+$ ]] ; then
            echo 'Please use an integer value for output time' && exit 0
        else
            if [ -n "${INTIME}" ] && ! [ "${OUTTIME}" -gt "${INTIME}" ] ; then
                echo "Error! Output time must be greater than input time!" && exit 1
            else
                echo "outpoint ${OUTTIME}" >> "${IO}"
            fi
        fi
    fi

    #Create Fingerprint
    ffmpeg -f concat -safe 0 -i "${IO}" -vf signature=format=xml:filename="${TEMPFINGERPRINT}" -map 0:v -f null -
    "${XMLSTARLET}" sel -N "m=urn:mpeg:mpeg7:schema:2001" -t -m "m:Mpeg7/m:DescriptionUnit/m:Descriptor/m:VideoSignatureRegion/m:VSVideoSegment" -v m:StartFrameOfSegment -o ':' -v m:EndFrameOfSegment -o ':' -m m:BagOfWords -v "translate(.,' ','')" -o ':' -b -n "${TEMPFINGERPRINT}" > "${TEMPFINGERPRINT_SORTED}"

    #Sort extract relevant values from fingerprint and sort for parsing
    (IFS=$'\n'
    for i in $(cat "${TEMPFINGERPRINT_SORTED}") ; do
        hash1=$(echo "${i}" | cut -d':' -f3)
        hash2=$(echo "${i}" | cut -d':' -f4)
        hash3=$(echo "${i}" | cut -d':' -f5)
        hash4=$(echo "${i}" | cut -d':' -f6)
        hashdec1="$((2#$(echo "${hash1}" | cut -c -26)))"
        hashdec2="$((2#$(echo "${hash1}" | cut -c 27-53)))"
        hashdec3="$((2#$(echo "${hash1}" | cut -c 54-80)))"
        hashdec4="$((2#$(echo "${hash1}" | cut -c 81-107)))"
        hashdec5="$((2#$(echo "${hash1}" | cut -c 108-134)))"
        hashdec6="$((2#$(echo "${hash1}" | cut -c 135-161)))"
        hashdec7="$((2#$(echo "${hash1}" | cut -c 162-188)))"
        hashdec8="$((2#$(echo "${hash1}" | cut -c 189-215)))"
        hashdec9="$((2#$(echo "${hash1}" | cut -c 216-242)))"
        echo "SELECT objectIdentifierValue,startframe,endframe,hash1,hash2 FROM fingerprints WHERE BIT_COUNT(hash1 ^ '${hashdec1}') + BIT_COUNT(hash2 ^ '${hashdec2}') + BIT_COUNT(hash3 ^ '${hashdec3}') + BIT_COUNT(hash4 ^ '${hashdec4}') + BIT_COUNT(hash5 ^ '${hashdec5}') + BIT_COUNT(hash6 ^ '${hashdec6}') + BIT_COUNT(hash7 ^ '${hashdec7}') + BIT_COUNT(hash8 ^ '${hashdec8}') + BIT_COUNT(hash9 ^ '${hashdec9}') <= 2" | mysql --login-path="${DBLOGINPATH}"  "${DBNAME}" | tr '\t' ' ' | grep -v "objectIdentifierValue" >> "${RESULTS}"
    done)
    echo
    cat "${RESULTS}" | sort -u
done
