// UNTESTED STARTER.
targetScope = 'resourceGroup'

param workspaceName string
param location string
param retentionDays int = 30
param dailyCapGb int = 1
param tags object = {}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionDays
    workspaceCapping: {
      dailyQuotaGb: dailyCapGb
    }
  }
}

output workspaceId string = workspace.id