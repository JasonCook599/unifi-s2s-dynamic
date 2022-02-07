#!/bin/vbash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
function error() {
    echo "ERROR: $1"
}

function throw() {
    echo "FATAL ERROR: $1"
    if [ -z "$2" ]; then
        exit 1
    else
        exit $2
    fi
}

# Get the remote DNS address from the first parameter.
if [ -z $1 ]; then
    throw "You must spesify the remote DNS address with the first parameter."
else
    RemoteDNS=$1
fi

LocalIP=$(curl https://ifconfig.me/ip) #The IP address of this sevice.
RemoteIP=$(host $RemoteDNS | grep -Pom 1 '[0-9.]{7,15}') || throw "$RemoteDNS doesn't resolved to an IP."
OldRemoteIP=$(</config/UpdateVpnIps.config)
CMD="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"
Show="$CMD show vpn ipsec site-to-site peer $OldRemoteIP"
Set="$CMD set vpn ipsec site-to-site peer $RemoteIP"

echo "Using remote IP of $RemoteIP via $RemoteDNS"
echo "Old remote IP is $OldRemoteIP"
echo "Using local IP of $LocalIP"

echo "Checking if Remote IP changed."
if [[ "$($CMD show vpn ipsec site-to-site peer $RemoteIP)" == "Configuration under specified path is empty" ]]; then
    $CMD begin
    echo "Remote IP changed from $OldRemoteIP to $RemoteIP."
    echo "Copying settings to new remote IP address"

    $Set description "Updated automatically at $(date)"

    Current=$($Show authentication mode)
    $Set authentication $Current

    Current=$($Show authentication pre-shared-secret)
    $Set authentication $Current

    Current=$($Show connection-type)
    $Set $Current

    Current=$($Show ike-group)
    $Set $Current

    $Set local-address $LocalIP # Updating local IP Address

    Current=$($Show vti bind)
    $Set vti $Current

    Current=$($Show vti esp-group)
    $Set vti $Current

    $CMD delete vpn ipsec site-to-site peer $OldRemoteIP

    $CMD commit
    $CMD save
    $CMD end

    echo $RemoteIP >/config/UpdateVpnIps.config # Save current remote IP for future runs.
    exit 0
else
    $Set description "Updated automatically at $(date)"
    echo "Remote IP didn't change."
fi

echo "Checking if local IP changed."
if [[ "$LocalIP" != "$($CMD show vpn ipsec site-to-site peer $RemoteIP local-address | grep -Pom 1 '[0-9.]{7,15}')" ]]; then
    $CMD begin
    echo "Local IP changed. Updating configuration with peer $RemoteIP"
    $CMD set vpn ipsec site-to-site peer $RemoteIP local-address $LocalIP
    $Set description "Updated automatically at $(date)"
    $CMD commit
    $CMD save
    $CMD end
else
    echo "Local IP didn't change."
fi
