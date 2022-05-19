# Description
Certify the Web (CtW) runs Powershell scripts only as local system account, but for auto-changing the certificate in Azure AD Application Proxy we need to store the user credentials. Because of this the Windows Task Scheduler is used to run the Update-AzureADAppProxyCertificate.ps1 in user context. And the credentials, including the pfx file password is stored in Windows Credential Manager.

The .pfx CtW generates needs to be password protected!

Every time the deployment task runs it starts the Start-ScheduledTask.ps1 which changes the scheduled task action arguments to match the new .pfx file name. The .pfx file name is passed by the $result parameter.

# Usage
1. Copy all files in a folder that won't be deleted (e.g. c:\tools\subfolder).
2. Duplicate or rename the example-config.json to config.json, edit it to match your infrastructure. For details about the config file have a look at the configuration section.
3. Run the setup.ps1 script, the required scheduled task will be created and the Azure user such as the .pfx file password will be stored in Windows Credential Manager by the provided names from the config file. You will be promted to enter some information:
4. Add a deployment task in the CtW configuration as follows:
    - Task Type: *Run Powershell Script*
    - Task Name: *Update Azure AD App Proxy Certificate*
    - Trigger: *Run On Success*
    - Authentication: *Local (as current service user)*
    - Program/Script: *Full\Path\to\Start-ScheduledTask.ps1*
    - Pass Result as First Arg: *checked*
    - Impersonation Logon Type: *Batch*
    - Arguments (optional): primaryUrl=<CertificateUrlSpecifiedAtConfigFile>
    - Script Timeout Mins.: *leaf empty*
    - Lauch New Process: *unchecked*
5. Test it with the play button in CtW.

# Parameter
n/a

# Configuration
The config.json contains the following parameters for each certificate you want to upload to Azure. The setup script loops trough the configuration, more entrys could be added as long as the json scheme is not changed. If you extend the configuration after the first run, you need to run the setup.ps1 again.

|Param | Description | Example Value |
| --- | --- | --- |
| primaryUrl | Certificates primary DNS | *app.example.tld* |
| taskName | Name for the scheduled task | *---UpdateAzADAppProxyCert---app.example.tld* |
| azureUserCredMgrTarget | Display name at Credential Manager for the Azure user entry. The same name could be used for multible certificates if they are at the same Azure tenant | *---AzAppAdmin--example.tld* |
| azurePFXCredMgrTarget | Display name at Credential Manager for the pfx file password entry. | *---PfxPw--example.tld* | 
| tenantID | Azure Tenant ID | *00000000-0000-0000-0000-000000000000* |
| appRegistrationObjectID | Azure AD App Registration Object ID | *00000000-0000-0000-0000-000000000000* |