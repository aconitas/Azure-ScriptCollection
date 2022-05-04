# Description
Certify the Web (CtW) runs Powershell scripts only as local system account, but for auto-changing the certificate in Azure AD Application Proxy we need to store the user credentials. Because of this the Windows Task Scheduler is used to run the Update-AzureADAppProxyCertificate.ps1 in user context.

The .pfx CtW generates needs to be password protected! 

Every time the deployment task runs it starts the Start-ScheduledTask.ps1 which changes the scheduled task action arguments to match the new .pfx file name. The .pfx file name is passed by the $result parameter.

# Usage
1. Copy all scripts in a folder that won't be deleted (e.g. c:\tools\subfolder).
2. Run the setup.ps1 script, it will create a config.json, the required scheduled task and stores the Azure user such as the .pfx file password in Windows Credential Manager. You will be promted to enter some information:
    - TaskName
    - TenantID
    - AppRegistrationObjectID
    - Azure User with Application Administrator Role (username@domain.tld; MFA not supported!)
    - PFX File Password
3. Add a deployment task in the CtW configuration as follows:
    - Task Type: *Run Powershell Script*
    - Task Name: *Update Azure AD App Proxy Certificate*
    - Trigger: *Run On Success*
    - Authentication: *Local (as current service user)*
    - Program/Script: *Full\Path\to\Start-ScheduledTask.ps1*
    - Pass Result as First Arg: *checked*
    - Impersonation Logon Type: *Batch*
    - Arguments (optional): *leaf empty*
    - Script Timeout Mins.: *leaf empty*
    - Lauch New Process: *unchecked*
4. Test it with the play button in CtW.

# Parameter
There are only a few parameters for the Setup-Script.ps1 but I recommend to run the script without parameters an let it ask you all it needs.

| Parameter | Default Value | Description |
|---|---|---|
| TaskName | n/a | Display Name for Scheduled Task |
| TenantID | n/a | Microsoft Tenant ID, can be shown in Azure Portal |
| AppRegistrationObjectID | n/a | Object ID of the App Registration for your App. |