# TODO: set variables
$studentName = "lawrence"
$rgName = "$studentName-lc0820-ps-rg"
$vmName = "$studentName-lc0820-ps-vm"
$vmSize = "Standard_B2s"
$vmImage = "$(az vm image list --query "[? contains(urn, 'Ubuntu')] | [0].urn" -o tsv)"
$vmAdminUsername = "student"
$vmAdminPassword= "LaunchCode-@zure1"
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

#just incase
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

# check the image variable, want the 2019 one image contains image 2012
# TODO: provision RG
az configure --default location=eastus
az group create -n $rgName
az configure --default group="$rgName"

# TODO: provision VM
$vmData="$(az vm create -n "$vmName" --size "$vmSize" --image "$vmImage" --admin-username "$vmAdminUsername" --admin-password $vmAdminPassword --authentication-type password --assign-identity --query "[ identity.systemAssignedIdentity, publicIpAddress ]")"

# TODO: capture the VM systemAssignedIdentity
$vmID="$(az vm show --query "identity.systemAssignedIdentity")"
$vmIP="$(az vm show --query "publicIpAddress")"

# TODO: open vm port 443
az vm open-port --port 443
az configure --default vm="$vmName"

# provision KV
az keyvault create -n "$kvName" --enable-soft-delete false --enabled-for-deployment true

# TODO: create KV secret (database connection string)
az keyvault secret set --vault-name "$kvName" -n "$kvSecretName" --value "$kvSecretValue"
az keyvault set-policy --name "$kvName" --object-id "$vmID" --secret-permissions list get

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh

# TODO: print VM public IP address to STDOUT or save it as a file
Write-Output "$vmIP"