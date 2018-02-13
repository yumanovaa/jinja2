class Template 

{
    [string]$Template

    Template ([string]$template) {
        $this.Template = $template
    }

    [string]render ([string]$string) {
        <#foreach ($line in $this.Template) {
            if ($line -match "{{") {
                Write-Host $line
            }
        }#>

        return $this.Template -replace '{{ name }}',$string
    }
}

function Get-Template([string]$Template) {
    return [Template]::new($Template)
}


Export-ModuleMember -Function Get-Template

<#public class jinja2 : Template {

}

$DataSource = "CRMDB"#>