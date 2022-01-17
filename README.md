# Unifi Site-to-Site VPNs with Dynamic IPs
## Gateway Setup
- Copy `UpdateVpnIps.sh` to `/config/scripts/UpdateVpnIps.sh`. 
- Run `chmod +x /config/scripts/UpdateVpnIps.sh` to mark the script as executable.
- Run the following commands to save the current remote IP address. Update `host.example.com` to your dynamic dns host name. 

      RemoteIP=$(host example.com | grep -Pom 1 '[0-9.]{7,15}') && echo $RemoteIP || echo "ERROR: That host doesn't resolved to an IP."
      echo $RemoteIP > /config/UpdateVpnIps.config

### Unifi Controller
Add the above script as a scheduled task in [`config.gateway.json`](https://help.ui.com/hc/en-us/articles/215458888-UniFi-USG-Advanced-Configuration). You can use the [sample file](config.gateway.json) if this doesn't already exist.