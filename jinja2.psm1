class Template 

{
    [string]$Template
    [string]$BLOCK_START_STRING = '{%'
    [string]$BLOCK_END_STRING = '%}'
    [string]$VARIABLE_START_STRING = '{{'
    [string]$VARIABLE_END_STRING = '}}'
    [string]$COMMENT_START_STRING = '{#'
    [string]$COMMENT_END_STRING = '#}'
    #$VARIABLE_STRING = "{{.\w*.}}"
    #$BLOCK_STRING = "{%.\w*.%}"
    #$COMMENT_STRING = "{#.\w*.#}"

    Template ([string]$template) {
        $this.Template = $template
    }

    [string]render ($dictionary) {
        [string]$Rezult = $this.Template
        if ($dictionary.GetType().Name -eq "Hashtable") {
            foreach ($key in $dictionary.keys) {
                if ($Rezult -match ($this.VARIABLE_START_STRING + '\s*' + $key  + '\s*' + $this.VARIABLE_END_STRING)){
                    $Rezult = $Rezult -replace ($this.VARIABLE_START_STRING + '\s*' + $key  + '\s*' + $this.VARIABLE_END_STRING),($dictionary[$key])
                }
            }
        }
        return $Rezult
    }
}

function Set-Template([string]$Template) {
    return [Template]::new($Template)
}

Export-ModuleMember -Function Set-Template