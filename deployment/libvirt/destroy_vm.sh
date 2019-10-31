SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}" )" )"
source ${SCRIPT_DIR}/functions.sh

while getopts "n:d" o; do
    case "${o}" in
        n)
            VMNAME="$OPTARG"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z ${VMNAME} ]]; then
    exit -1
fi

DOMAIN_DIRECTORY=vms
DOMAIN_FILE=$DOMAIN_DIRECTORY/$VMNAME.xml

if virsh list --all --name | grep ${VMNAME}; then
    STATUS=$(virsh list --all | grep ${VMNAME} | awk '{ print $3}')
    if ([ "$STATUS" == "running" ])
    then
        sudo virsh destroy ${VMNAME}
    fi
    sudo virsh undefine ${VMNAME}
    delete_disk /var/lib/libvirt/images/${VMNAME}-0.img
    delete_disk /var/lib/libvirt/images/${VMNAME}-1.img
    delete_disk /var/lib/libvirt/images/${VMNAME}-2.img
    [ -e ${DOMAIN_FILE} ] && delete_xml ${DOMAIN_FILE}
fi