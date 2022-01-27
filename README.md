# Sonarqube Community On Azure

This button will deploy the latest Sonarqube Community to Azure.

It creates:

- An App Service plan
- An Azure SQL server and database
- An App Service with Docker on Linux

The App Service has configuration to deal with the Elestic Search memory issue.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FEonasdan%2Fsonarqube-azure%2Fmain%2Fsonarqube.json" target="_blank">
  <img src="https://aka.ms/deploytoazurebutton"/>
</a>
