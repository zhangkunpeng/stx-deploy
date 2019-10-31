
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}" )" )"
source ${SCRIPT_DIR}/functions.sh

while getopts "i:n:" o; do
    case "${o}" in
        i)
            ISOIMAGE=$(readlink -f "$OPTARG")
            ;;
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

if [[ -n "${ISOIMAGE}" ]]; then
    iso_image_check ${ISOIMAGE}
fi

DISKNUM=${DISKNUM:-3}

BRIDGE_INTERFACE=${BRIDGE_INTERFACE:-stxbr}
CONTROLLER=${CONTROLLER:-controller}
WORKER=${WORKER:-worker}
WORKER_NODES_NUMBER=${WORKER_NODES_NUMBER:-1}
STORAGE=${STORAGE:-storage}
STORAGE_NODES_NUMBER=${STORAGE_NODES_NUMBER:-1}
DOMAIN_DIRECTORY=vms

[ ! -d ${DOMAIN_DIRECTORY} ] && mkdir ${DOMAIN_DIRECTORY}

ls ${SCRIPT_DIR}/${DOMAIN_DIRECTORY} | grep "${VMNAME}.xml"
if [ $? -eq 0 ];then
    echo "${VMNAME} is exist, please set another one."
    exit 1
fi

DOMAIN_FILE=${DOMAIN_DIRECTORY}/${VMNAME}.xml
cp controller_allinone.xml ${DOMAIN_FILE}
sed -i -e "
    s,NAME,${VMNAME},
    s,DISK0,/var/lib/libvirt/images/${VMNAME}-0.img,
    s,DISK1,/var/lib/libvirt/images/${VMNAME}-1.img,
    s,DISK2,/var/lib/libvirt/images/${VMNAME}-2.img,
    s,%BR1%,${BRIDGE_INTERFACE}1,
    s,%BR2%,${BRIDGE_INTERFACE}2,
    s,%BR3%,${BRIDGE_INTERFACE}3,
    s,%BR4%,${BRIDGE_INTERFACE}4,
" ${DOMAIN_FILE}

sudo qemu-img create -f qcow2 /var/lib/libvirt/images/${VMNAME}-0.img 600G
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/${VMNAME}-1.img 200G
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/${VMNAME}-2.img 200G

if [ -f "${ISOIMAGE}" ]; then
    sed -i -e "s,ISO,${ISOIMAGE}," ${DOMAIN_FILE}
else
    sed -i -e "s,ISO,," ${DOMAIN_FILE}
fi
sudo virsh define ${DOMAIN_FILE}