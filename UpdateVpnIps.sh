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

echo "Updating VPN connection from $LocalIP to $RemoteDNS ($RemoteIP)"
$CMD begin

if [[ "$($CMD show vpn ipsec site-to-site peer $RemoteIP)" == "Configuration under specified path is empty" ]]; then    
    echo "Remote IP changed from $OldRemoteIP to $RemoteIP. Copying settings to new remote IP address."
    $Set authentication $($Show authentication mode)
    $Set authentication $($Show authentication pre-shared-secret)
    $Set $($Show connection-type)
    $Set $($Show ike-group)
    $Set local-address $LocalIP # Updating local IP Address
    $Set vti $($Show vti bind)
    $Set vti $($Show vti esp-group)
    if [[ $OldRemoteIP != $RemoteIP ]]; then $CMD delete vpn ipsec site-to-site peer $OldRemoteIP ; fi #sanity check don't delete what youre working on
    echo $RemoteIP >/config/UpdateVpnIps.config # Save current remote IP for future runs.
else
    echo "Remote IP didn't change."
fi

if [[ "$LocalIP" != "$($CMD show vpn ipsec site-to-site peer $RemoteIP local-address | grep -Pom 1 '[0-9.]{7,15}')" ]]; then
    echo "Local IP changed. Updating configuration with peer $RemoteIP"
    $CMD set vpn ipsec site-to-site peer $RemoteIP local-address $LocalIP
else
    echo "Local IP didn't change."
fi
$Set description "Updated automatically at $(date)"
$CMD commit
$CMD save
$CMD end
