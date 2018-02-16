class Enveroment 
{
    [string]$BLOCK_START_STRING = '{%'
    [string]$BLOCK_END_STRING = '%}'
    [string]$VARIABLE_START_STRING = '{{'
    [string]$VARIABLE_END_STRING = '}}'
    [string]$COMMENT_START_STRING = '{#'
    [string]$COMMENT_END_STRING = '#}'
}

class Template : Enveroment
{
    [string]$TemplateString
    [System.IO.FileInfo]$TemplateFile
    [System.Object]$TemplateArrayString
    [pscustomobject]$DataCollection

    Template ($template) {
        switch ($template.GetType()) {
            System.IO.FileInfo {$this.TemplateFile = $template}
            System.Object[] {$this.TemplateArrayString = $template}
            DEFAULT {$this.TemplateString = $template}
        }
        $this.DataCollection = @()
    }

    [string]render ($dictionary) {
        [string]$Rezult = $this.TemplateString
        if ($dictionary.GetType().Name -eq "Hashtable") {
            foreach ($key in $dictionary.keys) {
                if ($Rezult -match ($this.VARIABLE_START_STRING + '\s*' + $key  + '\s*' + $this.VARIABLE_END_STRING)){
                    $Rezult = $Rezult -replace ($this.VARIABLE_START_STRING + '\s*' + $key  + '\s*' + $this.VARIABLE_END_STRING),($dictionary[$key])
                }
            }
        } else {
            $Rezult = "FAILED! Metod render accept only hashtable!"
        }
        return $Rezult
    }

    hidden [string]renderArray() {
        [string]$Rezult = $this.TemplateString
        foreach ($array in $this.DataCollection) {
            for ($i = 0; $i -le $array.Array.Count; $i++) {
                foreach ($key in $array.Array[$i].keys) {
                    $Rezult = $Rezult -replace ("{{\s*" + $array.Name + '.' + $key + "\s*}}"), $array.Array[$i][$key]
                }
            }
        }
        return $Rezult
    }

    [System.Object]renderFile($dictionary) {
        if ($dictionary.GetType().Name -eq "Hashtable") {
            $Rezult = $this.TemplateArrayString
            for ($i = 0; $i -le $Rezult.Count; $i++) {
                Switch -regex ($Rezult[$i]) {
                    '{{\s*\w+\s*}}' {
                        $this.TemplateString = $Rezult[$i]
                        $Rezult[$i] = $this.render($dictionary)
                    }
                    '{{\s*\w+\.\w+\s*}}' {
                        $this.TemplateString = $Rezult[$i]
                        $Rezult[$i] = $this.renderArray()
                    }
                }
            }
        } else {
            $Rezult = "FAILED! Metod render accept only hashtable!"
        }
        return $Rezult
    }

    Add ([string]$name, [Hashtable]$Array) {
        $ObjectArray = New-Object pscustomobject
        if ($this.DataCollection.Count -eq 0) {
            $this.DataCollection += $this.CreateNewArray($name,$Array)
        } else {
            [boolean]$existArray = $false
            for ($i = 0; $i -le $this.DataCollection.Count; $i++) {
                if ($this.DataCollection[$i].Name -eq $name) {
                    $existArray = $true
                    $this.DataCollection[$i].Array += $Array
                }
                if (!$existArray) {
                    $this.DataCollection += $this.CreateNewArray($name,$Array)
                }
            }
        }
    }

    [pscustomobject]Show(){
        return $this.DataCollection
    }

    hidden [pscustomobject]CreateNewArray ([string]$name, [Hashtable]$Array) {
        $ObjectArray = New-Object pscustomobject
        $ObjectArray = @{
            Name = $name
            Array = @()
        }
        $ObjectArray.Array += $Array
        return $ObjectArray
    }
}

function Set-Template($Template) {
    return [Template]::new($Template)
}

Export-ModuleMember -Function Set-Template