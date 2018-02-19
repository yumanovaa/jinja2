# Jinja2 for PowerShell

## Basic API Usage
```PowerShell
Import-Module –Name .\jinja2 -PassThru

$template = Set-Template('Hello {{ Name }}, I am in {{Make }} {{Model}}!')
$template.AddVareables(@{
    name = "Alex"
    Make = "Ford"
    Model = "Mustang"
    TestValue = "Test permanent key"
    })
$template.render()
PS C:\>Hello Alex, I am inside Ford Mustang!
```
## With string Array

Web.config.jn2
```
<?xml version="1.0"?>
<configuration>
  <configSections>
    <section name="environments" type="something type"/>
  </configSections>
  <connectionStrings>
    <add name="{{ TestValue }}" connectionString="Data Source={{ CRM.DBHost }};Initial Catalog={{ CRM.DBName }};Integrated Security=True;/>
  </connectionStrings>
...
```

```PowerShell
$template = Set-Template(Get-Content .\Web.config.jn2)
$variables = @{
    DBHost = "mssql.uat.local"
    DBName = "CRMDB"
}

$template.AddArray("CRM", $variables)
Set-Content -Path .\Web.config -Value ($template.renderFile())
```

## With Arrays
Web.config.jn2
```
...
  <environments>
    {% for key in keys %}  			  
	<add key="{{ key.Name }}" value="{{ key.value }}"/>
	<add key="{{ TestValue }}" value="{{ CRM.DBName }}"/>
	{% endfor %}
  </environments>
...
    <client>
      {% for environment in environments %}  			  
	  <endpoint address="{{ environment.address }}" binding="{{ environment.binding }}" contract="{{ environment.contract }}" name="{{ environment.name }}"/>
	  {% endfor %}
    </client>
...
```

```PowerShell
$template = Set-Template(Get-Content .\Web.config.jn2)
$variables = @{
    Name = "Key1"
    Value = "200"
}
$template.AddArray("Keys", $variables)
$variables = @{
    Name = "Key2"
    Value = "300"
}
$template.AddArray("Keys", $variables)
$variables = @{
    Name = "Key3"
    Value = "400"
}
$template.AddArray("Keys", $variables)
$variables = @{
    name = "Name1"
    address = "https://address.1"
    binding = "binding.1"
    contract = "contract.1"
}
$template.AddArray("environments", $variables)
$variables = @{
    name = "Name2"
    address = "https://address.2"
    binding = "binding.2"
    contract = "contract.2"
}
$template.AddArray("environments", $variables)
$variables = @{
    name = "Name3"
    address = "https://address.3"
    binding = "binding.3"
    contract = "contract.3"
}
$template.AddArray("environments", $variables)

Set-Content -Path .\Web.config -Value ($template.renderFile($variables))
```