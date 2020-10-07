# Office 365 monitoring in Solarwinds
This is a script for generating an APM template for monitoring O365 services in Solarwinds.

This is a mostly rewritten template of [this one from Thwack](https://thwack.solarwinds.com/t5/SAM-Documents/Office-365-Service-Health-using-Office-365-Service/ta-p/518526). I had to rewrite it to support ignoring "Advisory" messages.

The services monitored can be found in the [data/o365-services.json](/blob/master/data/o365-services.json) file.

## Steps
1. Check [Prerequisites](#Prerequisites)
2. Either [Download](#Download) the template or [build it yourself](#Build-it-yourself)
3. [Import it to Solarwinds](#Usage-in-Solarwinds)

## Prerequisites
- [Azure AAD Application](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps)
  - With these permissions granted:
    - Reports.Read.All [Delegated]
    - Reports.Read.All [Application]
    - ServiceHealth.Read [Application]
  - Tenant ID
  - Application ID
  - Application Secret
- [NodeJS](https://nodejs.org/en/download/) (If you are going to [build](#Build-it-yourself) the template yourself)

## Download
You can download the template from the [releases page](/releases) under assets.

Now search & replace `&lt;Tenant-ID&gt;` with your Azure AAD Tenant-ID in the template file. Or you will have to do it manually in SW.

## Build it yourself
```sh
# Clone the repo
git clone https://github.com/vtfk/solarwinds-o365-monitoring
cd solarwinds-o365-monitoring

# Copy the template.env file
cp template.env .env
# Open the .env file and add your Azure Tenant-ID.
vim .env

# Install dependencies
npm i
# Build the template
npm start
```

## Usage in Solarwinds
### Importing the template
1. Go to "SAM Settings".
2. Then "Manage Templates" under "APPLICATION MONITOR TEMPLATES".
3. Import the file from the toolbar (at the top of the table).

### Creating a node
1. Go to "Manage Nodes"
2. Click "Add Node"
3. Hostname/IP can be anything valid (not used). Eg. "status.office.com".
4. Polling Method should be "External Node".
5. Polling Engine should be a server with Powershell installed.
6. Click next.
7. Show only the tag "Office 365" and choose the "Office 365 Service Health Status" template.
8. Add new credentials where
  - User Name: Application ID
  - Password: Application Secret
9. Click "Test" and all components should start testing. (If it fails with a "400 Bad request", check if you replaced the `&lt;Tenant-ID&gt;` in the template)
10. Click "Next", and now you have access to all the components.

### Including "Advisory" messages in status
By default it ignores messages with the classification "Advisory". If you pass "true" as a third argument to the script in Solarwinds, it will include them.

## License
[MIT](LICENSE)