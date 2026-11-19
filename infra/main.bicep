// UNTESTED STARTER. Run 'az deployment sub what-if' in a throwaway subscription first.
// Scope: subscription. Fictional org: Contoso Defense. Replace every placeholder.
targetScope = 'subscription'

@description('Short org prefix used in names.')
param orgPrefix string = 'contoso'

@description('Primary Azure region.')
param location string = 'eastus2'

@description('Allowed regions for resources and resource groups.')
param allowedLocations array = [
  'eastus2'
  'centralus'
]

@description('Common tags. Never put sensitive data in tags.')
param tags object = {
  Environment: 'lab'
  Owner: 'cloud-security-lab'
  CostCenter: 'lab'
  DataClassification: 'Non-CUI'
}

@description('Log Analytics retention in days.')
@minValue(30)
param logRetentionDays int = 30

@description('Log Analytics daily cap in GB. Keep low in a lab.')
param dailyCapGb int = 1

@description('Monthly budget in USD.')
param budgetAmount int = 5

@description('Email addresses for budget alerts.')
param budgetContactEmails array

@description('First day of the current month, used as the budget start date.')
param budgetStartDate string = utcNow('yyyy-MM-01')

@description('Defender for Cloud plans. Free = no charge. Standard starts a trial then bills.')
param defenderPlans object = {
  VirtualMachines: 'Free'
  AppServices: 'Free'
  SqlServers: 'Free'
  StorageAccounts: 'Free'
  Containers: 'Free'
  KeyVaults: 'Free'
  Arm: 'Free'
}

var resourceGroupNames = [
  format('rg-{0}-management', orgPrefix)
  format('rg-{0}-connectivity', orgPrefix)
  format('rg-{0}-identity', orgPrefix)
  format('rg-{0}-cui-enclave', orgPrefix)
  format('rg-{0}-corp', orgPrefix)
]

// Built-in policy definitions (IDs from the lab guide; confirm with az policy definition show).
var nist800171r2InitiativeId = '/providers/Microsoft.Authorization/policySetDefinitions/03055927-78bd-4236-86c0-f36125a10dc9'
var allowedLocationsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'

// 1. Resource groups (tagged so a require-tag policy would pass)
resource rgs 'Microsoft.Resources/resourceGroups@2024-03-01' = [for name in resourceGroupNames: {
  name: name
  location: location
  tags: tags
}]

// 2. Log Analytics workspace in the management resource group
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'logAnalytics'
  scope: rgs[0]
  params: {
    workspaceName: format('log-{0}-lab-{1}', orgPrefix, location)
    location: location
    retentionDays: logRetentionDays
    dailyCapGb: dailyCapGb
    tags: tags
  }
}

// 3. Defender for Cloud pricing tiers (all Free by default)
resource defender 'Microsoft.Security/pricings@2024-01-01' = [for plan in items(defenderPlans): {
  name: plan.key
  properties: {
    pricingTier: plan.value
  }
}]

// 4. Policy: NIST SP 800-171 Rev 2 initiative (audit). Needs a managed identity and location.
resource nistAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'nist-800-171-r2'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'NIST SP 800-171 Rev. 2'
    policyDefinitionId: nist800171r2InitiativeId
    enforcementMode: 'Default'
  }
}

// 5. Policy: allowed locations
resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'allowed-locations'
  properties: {
    displayName: 'Allowed locations'
    policyDefinitionId: allowedLocationsPolicyId
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

// 6. Budget alert at subscription scope
resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: format('budget-{0}-lab', orgPrefix)
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
    }
    notifications: {
      actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: budgetContactEmails
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: budgetContactEmails
      }
    }
  }
}

output logWorkspaceId string = logAnalytics.outputs.workspaceId
output resourceGroupIds array = [for i in range(0, length(resourceGroupNames)): rgs[i].id]