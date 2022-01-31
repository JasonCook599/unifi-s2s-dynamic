# Introduction
Unifi allows you to create a site-to-site VPN to connect two different sites. When both sites are hosted on the same controller, dynamic IP address changes are handled automatically.

If the sites are on different controllers, you must manually update the configuration for both sites if either IP address changes. This script allows for IP address changes to be handled automatically.

# Setup
You must complete these steps on the devices in both sites.

## Gateway Setup
Run the following commands on your gateway to download the script.

    # Download the script
    sudo curl -s -o /config/scripts/UpdateVpnIps.sh https://raw.githubusercontent.com/koinoniacf/unifi-s2s-dynamic/main/UpdateVpnIps.sh

    # Mark the script as executable
    sudo chmod +x /config/scripts/UpdateVpnIps.sh

    # Replace example.com with the remote site's DNS name.
    RemoteIP=$(host example.com | grep -Pom 1 '[0-9.]{7,15}') && echo $RemoteIP || echo "ERROR: That host doesn't resolved to an IP."
    
    # Save the current remote IP
    echo $RemoteIP > /config/UpdateVpnIps.config

    # Verify remote IP saved correctly
    cat /config/UpdateVpnIps.config

## Unifi Controller Setup
### Dynamic DNS
If you haven't already, you should set up dynamic dns so the you can find the IP address when it changes. In the controller, navigate to `Settings > Services > Dynamic DNS > Create new dynamic DNS`. Fill in the fields with the details given to you by your DNS provider.

### Running the script
For the script to run, you need to create a task schedule in your [`config.gateway.json`](https://help.ui.com/hc/en-us/articles/215458888-UniFi-USG-Advanced-Configuration) file. If you haven't already created this file, you can follow the steps below to use the sample [`config.gateway.json`](config.gateway.json). If the file already exists, you will need to create the task manually. See these pages for more information on [`<unifi_base>`](https://help.ui.com/hc/en-us/articles/115004872967) and [`<site_ID>`](https://help.ui.com/hc/en-us/articles/215458888-UniFi-How-to-further-customize-USG-configuration-with-config-gateway-json#:~:text=The%20site_ID%20can,s/ceb1m27d/dashboard).

    # Change directory to appropriate site
    # Update <unifi_base> and <site_ID> to match your configuration
    cd <unifi_base>/data/sites/<site_ID>

    # Download the script
    # THIS WILL OVERWRITE config.gateway.json
    sudo curl -s -o config.gateway.json https://raw.githubusercontent.com/koinoniacf/unifi-s2s-dynamic/main/config.gateway.json

    # Set proper ownership permissions
    chown unifi:unifi config.gateway.json

    # Open the file for editing
    sudo vi config.gateway.json

- Use the arrow keys to navigate to `example.com`
- Press `i` to enter insert mode
- Replace `example.com` with the remote site's DNS name
- Press `Esc`
- Type `:wq`
- Press `Enter`

### Provision the changes
In the controller, navigate to `Devices > Gateway > Config > Manage device > Provision`

# Troubleshooting
## Remote IP Out of Sync
The script is set up to copy settings from the old to new IP. This is done to retain as much functionality as possible in the Unifi Controller.

On occasion, the IP address saved by the script and the remote IP address used by the gateway may go out if sync. This will cause the links to go down. When this occurs, simply add the new remote IP to the controller. Future IP changes will be handled by the script.