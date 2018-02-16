# Jinja2 for PowerShell

## Basic API Usage
```PowerShell
Import-Module –Name .\jinja2 -PassThru

$template = Set-Template('Hello {{ name }}, I am in {{Make }} {{Model}}!')
$template.render(@{
    name = "Alex"
    Make = "Ford"
    Model = "Mustang"
    Color = "Red"
    })

PS C:\>Hello Alex, I am inside Ford Mustang!
```
## Work with files template

Web.config.jn2
```
<?xml version="1.0"?>
<configuration>
  <configSections>
    <section name="environments" type="something type"/>
  </configSections>
  <connectionStrings>
    <add name="CRMDB" connectionString="Data Source={{ CRM.DBHost }};Initial Catalog={{ CRM.DBName }};Integrated Security=True;/>
  </connectionStrings>
...
```


```PowerShell
$template = Set-Template(Get-Content .\Web.config.jn2)
$variables = @{
    DBHost = "mssql.uat.local"
    DBName = "CRMDB"
}

$template.Add("CRM", $variables)
Set-Content -Path .\Web.config -Value ($template.renderFile($variables))
```