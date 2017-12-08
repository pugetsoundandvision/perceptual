#!/bin/bash
# makefingerprint generates a video perceptual hash for an input
SCRIPTDIR=$(dirname $(which "${0}"))
. "${SCRIPTDIR}/mmfunctions" || { echo "Missing '${SCRIPTDIR}/mmfunctions'. Exiting." ; exit 1 ;};
. "${SCRIPTDIR}/FINGERPRINTDB_CONFIG.txt" || { echo "Missing '${SCRIPTDIR}/FINGERPRINTDB_CONFIG.txt'. Exiting." ; exit 1 ;};
SUFFIX="_signature"
EXTENSION="xml"
RELATIVEPATH="metadata"

_report_fingerprint_db(){
    table_name="fingerprints"
    (IFS=$'\n'
    for i in ${VIDEOFINGERPRINT} ; do
    hash1=$(echo "$i" | cut -d':' -f3)
    hash2=$(echo "$i" | cut -d':' -f4)
    hash3=$(echo "$i" | cut -d':' -f5)
    hash4=$(echo "$i" | cut -d':' -f6)
    hash5=$(echo "$i" | cut -d':' -f7)
    hashdec1="$((2#$(echo "${hash1}" | cut -c -26)))"
    hashdec2="$((2#$(echo "${hash1}" | cut -c 27-53)))"
    hashdec3="$((2#$(echo "${hash1}" | cut -c 54-80)))"
    hashdec4="$((2#$(echo "${hash1}" | cut -c 81-107)))"
    hashdec5="$((2#$(echo "${hash1}" | cut -c 108-134)))"
    hashdec6="$((2#$(echo "${hash1}" | cut -c 135-161)))"
    hashdec7="$((2#$(echo "${hash1}" | cut -c 162-188)))"
    hashdec8="$((2#$(echo "${hash1}" | cut -c 189-215)))"
    hashdec9="$((2#$(echo "${hash1}" | cut -c 216-242)))"
    startframe=$(echo "$i" | cut -d':' -f1)
    endframe=$(echo "$i" | cut -d':' -f2)
    echo "INSERT INTO fingerprints (objectIdentifierValue,startframe,endframe,hash1,hash2,hash3,hash4,hash5,hash6,hash7,hash8,hash9) VALUES ('${MEDIA_ID}','${startframe}','${endframe}','${hashdec1}','${hashdec2}','${hashdec3}','${hashdec4}','${hashdec5}','${hashdec6}','${hashdec7}','${hashdec8}','${hashdec9}')" | mysql --login-path="${DBLOGINPATH}"  "${DBNAME}"
    done)
}

_fingerprint_to_db(){
VIDEOFINGERPRINT=$("${XMLSTARLET}" sel -N "m=urn:mpeg:mpeg7:schema:2001" -t -m "m:Mpeg7/m:DescriptionUnit/m:Descriptor/m:VideoSignatureRegion/m:VSVideoSegment" -v m:StartFrameOfSegment -o ':' -v m:EndFrameOfSegment -o ':' -m m:BagOfWords -v "translate(.,' ','')" -o ':' -b -n "${FINGERPRINT_XML}")
}

while [ "${*}" != "" ] ; do
    # get context about the input
    INPUT="${1}"
    shift
    if [ -z "${OUTPUTDIR_FORCED}" ] ; then
        [ -d "${INPUT}" ] && { OUTPUTDIR="$INPUT/metadata/${RELATIVEPATH}" && FINGERDIR="${INPUT}/metadata/fingerprints" ;};
        [ -f "${INPUT}" ] && { OUTPUTDIR=$(dirname "${INPUT}")"/${RELATIVEPATH}" && FINGERDIR="$(dirname "${INPUT}")/fingerprints" ;};
        [ ! "${OUTPUTDIR}" ] && { OUTPUTDIR="${INPUT}/metadata/${RELATIVEPATH}" && FINGERDIR="${INPUT}/metadata/fingerprints" ;};
    else
        OUTPUTDIR="${OUTPUTDIR_FORCED}"
        FINGERDIR="${OUTPUTDIR}/metadata/fingerprints"
    fi
    _unset_variables
    _find_input "${INPUT}"
    MEDIA_ID=$(basename "${INPUT}" | cut -d. -f1)

    if [ "${FINGERDIR}" != "" ] ; then
        _mkdir2 "${FINGERDIR}"
    fi
    #Generate Fingerprint
    SIGNATURE="${MEDIA_ID}""${SUFFIX}"."${EXTENSION}"
    _run_critical_event ffmpeg "${FFMPEGINPUT[@]}" -vf signature=format=xml:filename="${FINGERDIR}/${SIGNATURE}" -map 0:v -f null -
    FINGERPRINT_XML="${FINGERDIR}/${SIGNATURE}"

#Report to DB
    echo "Reporing to DB"
    _fingerprint_to_db
    _report_fingerprint_db
    gzip "${FINGERPRINT_XML}"
done
