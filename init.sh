#! /bin/bash

TARGET="staging"
WITH_DB=false
WITH_FILES=false

for i in "$@"; do
    case $i in
        --target=*)
            TARGET="${i#*=}"
            shift # past argument=value
        ;;
        --with-db)
            WITH_DB=true
            shift
        ;;
        --with-files)
            WITH_FILES=true
            shift
        ;;
        -*|--*)
            echo "Unknown option $i"
            exit 1
        ;;
        *)
        ;;
    esac
done

EXISTS=$(jq -e 'has("'"${TARGET}"'")' ./targets.json)

if [ "$EXISTS" = true ]; then
    HOST=$( jq -r ."${TARGET}".host ./targets.json)
    USER=$( jq -r ."${TARGET}".user ./targets.json)
    PORT=$( jq -r ."${TARGET}".port ./targets.json)
    ROOT=$( jq -r ."${TARGET}".site_root ./targets.json)
    LOCAL_URL=$( jq -r ."${TARGET}".local_url ./targets.json)
else
    echo "${TARGET} not found, exiting"
    exit
fi

depssh(){
    ssh_cmd=$1
    ssh -o StrictHostKeyChecking=no -p "$PORT" "$USER"@"$HOST" "cd ${ROOT} ; $ssh_cmd"
}

mkdir -p "$LANDO_WEBROOT"
cd "$LANDO_WEBROOT" || exit