using './main.bicep'

param environment = readEnvironmentVariable('AZURE_ENV_NAME', 'demo')
param projectName = 'als-private-spot'
param location = readEnvironmentVariable('AZURE_LOCATION', 'eastus2')
param jumpboxSshPublicKey = readEnvironmentVariable('JUMPBOX_SSH_PUBLIC_KEY', '')
