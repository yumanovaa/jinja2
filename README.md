# Jinja2 for PowerShell

## With string Array

Web.config.jn2
```HTML, XML
<?xml version="1.0"?>
<configuration>
  <configSections>
    <section name="environments" type="something type"/>
  </configSections>
  <connectionStrings>
    <add name="{{ TestValue }}" connectionString="Data Source={{ CRM.DataBaseAddress }};Initial Catalog={{ CRM.DataBaseName }};Integrated Security=True;/>
  </connectionStrings>
...
```

```PowerShell
$yaml = @"
TestValue: 'DATABASE_NAME'

CRM:
  - { DataBaseAddress: 'localhost', DataBaseName: 'CRMDB' }
"@
$template = Set-Template(Get-Content .\Web.config.jn2)
$template.SetDataCollection($yaml)
Set-Content -Path .\Web.config -Value ($template.renderFile())
```

## With Arrays
Web.config.jn2
```HTML, XML
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
$yaml = @"
TestValue: 'DATABASE_NAME'

CRM:
  - { DataBaseAddress: 'localhost', DataBaseName: 'CRMDB' }

Keys:
  - { Name: 'Key1', Value: '100' }
  - { Name: 'Key2', Value: '200' }
  - { Name: 'Key3', Value: '300' }
  
environments:
  - { name: 'Name1',  address: 'https://address.1', binding: 'binding.1', contract: 'contract.1'}
  - { name: 'Name2',  address: 'https://address.2', binding: 'binding.2', contract: 'contract.2'}
  - { name: 'Name3',  address: 'https://address.3', binding: 'binding.3', contract: 'contract.3'}
"@
$template = Set-Template(Get-Content .\Web.config.jn2)
$template.SetDataCollection($yaml)
Set-Content -Path .\Web.config -Value ($template.renderFile())
```

## "If" construction
Web.config.jn2
```HTML, XML
...
  <environments>
{% if CRM.Info %}  			  
	Variables exist!
{% endif %}
{% if name %}  			  
	Variables exist!
{% endif %}
{% if notExist %}  			  
	Variables exist!
{% endif %}
  </environments>
```
```PowerShell
$yaml = @"
TestValue: 'DATABASE_NAME'

CRM:
  - { DataBaseAddress: 'localhost', DataBaseName: 'CRMDB', Info: 'Info about this variable' }
  
Name: 'Alex'
"@
$template = Set-Template(Get-Content .\Web.config.jn2)
$template.SetDataCollection($yaml)
Set-Content -Path .\Web.config -Value ($template.renderFile())
```