# export_airwave_devices
A small script to export devices from AirWave and save them to a CSV list. 
The script uses the RestAPI from AirWave to search for the devices, using a search string, and will search for the device type in the resultset. It will than export the devices to a CSV file, which can be used to import those devices to another AirWave system. 

Usage
The script expects the settings.cfg to be in the same directory as the script itself. From that directory, you can run the script with the following options:
export_devices.ps1 -queryString queryString [-filterTypeString typeString]
    -queryString        This is the the search string and is mandatory.
    -filterTypeString   You can filter the output by the Type. This is                          optional. Possible types can be found here:
                        https://[airwave IP/Domain]]/nf/device_type_list