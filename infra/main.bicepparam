// UNTESTED STARTER. Replace the placeholder email.
using './main.bicep'

param orgPrefix = 'contoso'
param location = 'eastus2'
param allowedLocations = [
  'eastus2'
  'centralus'
]
param tags = {
  Environment: 'lab'
  Owner: 'cloud-security-lab'
  CostCenter: 'lab'
  DataClassification: 'Non-CUI'
}
param logRetentionDays = 30
param dailyCapGb = 1
param budgetAmount = 5
param budgetContactEmails = [
  'lab-owner@example.com'
]

// Deploy (what-if first):
//   az deployment sub what-if --location eastus2 --template-file main.bicep --parameters main.bicepparam
//   az deployment sub create --location eastus2 --template-file main.bicep --parameters main.bicepparam