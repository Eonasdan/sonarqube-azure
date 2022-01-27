@secure()
param sql_password string
param sql_server_name string
param sql_admin string = 'cube'
param db_name string = 'sonarqube'

param serviceplan_name string = 'sonarqube'
param site_name string

resource serviceplan_resource 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: serviceplan_name
  location: resourceGroup().location
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    freeOfferExpirationTime: '2022-02-04T14:02:00'
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource sql_server 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sql_server_name
  location: resourceGroup().location
  properties: {
    administratorLogin: sql_admin
    administratorLoginPassword: sql_password
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

resource sql_db 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  parent: sql_server
  name: db_name
  location: resourceGroup().location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CS_AS'
    maxSizeBytes: 2147483648
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
    isLedgerOn: false
  }
}

resource sql_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-05-01-preview' = {
  parent: sql_server
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sites_resource 'Microsoft.Web/sites@2021-02-01' = {
  name: site_name
  location: resourceGroup().location
  kind: 'app,linux,container'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${site_name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${site_name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serviceplan_resource.id
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|sonarqube:community'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 1
    }
  }
}

resource sites_config 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: sites_resource
  name: 'web'
  properties: {
    linuxFxVersion: 'DOCKER|sonarqube:community'
    appCommandLine: '-Dsonar.es.bootstrap.checks.disable=true'    
  }
}

var fqdn = sql_server.properties.fullyQualifiedDomainName

resource sites_appsettings 'Microsoft.Web/sites/config@2021-02-01' = {
  name: 'appsettings'
  parent: sites_resource
  properties: {
      SONARQUBE_JDBC_PASSWORD: sql_password
      SONARQUBE_JDBC_URL: 'jdbc:sqlserver://${fqdn};database=${db_name};user=${sql_admin}@${sql_server_name};password=${sql_password};encrypt=true;trustServerCertificate=false;hostNameInCertificate=${replace(fqdn, '${sql_server_name}.', '*.')};loginTimeout=30;'
      SONARQUBE_JDBC_USERNAME: sql_admin
      'sonar.search.javaAdditionalOpts': '-Dnode.store.allow_mmapfs=false'
  }
}

resource sites_binding 'Microsoft.Web/sites/hostNameBindings@2021-02-01' = {
  parent: sites_resource
  name: '${site_name}.azurewebsites.net'
  properties: {
    siteName: site_name
    hostNameType: 'Verified'
  }
}
