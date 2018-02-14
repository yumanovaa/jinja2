# Jinja2 for PowerShell

## Basic API Usage
```PowerShell
Import-Module –Name .\jinja2 -PassThru

$template = Set-Template('Hello {{ name }}, I am in {{Make }} {{ Model }}!')
$template.render(@{
    name = "Alex"
    Make = "Ford"
    Model = "Mustang"
    Color = "Red"
    })

PS C:\>Hello Alex, I am in Ford Mustang!
```
