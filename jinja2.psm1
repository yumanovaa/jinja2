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
    [hashtable]$variables

    Template ($template) {
        switch ($template.GetType()) {
            System.IO.FileInfo {$this.TemplateFile = $template}
            System.Object[] {$this.TemplateArrayString = $template}
            DEFAULT {$this.TemplateString = $template}
        }
        $this.DataCollection = @()
    }

    [pscustomobject]show () {
        return $this.DataCollection
    }

    [string]render () {
        [string]$Rezult = $this.TemplateString
        if ($this.variables.GetType().Name -eq "Hashtable") {
            foreach ($key in $this.variables.keys) {
                if ($Rezult -match ($this.VARIABLE_START_STRING + '\s*' + $key  + '\s*' + $this.VARIABLE_END_STRING)){
                    $Rezult = $Rezult -replace ($this.VARIABLE_START_STRING + '\s*' + $key  + '\s*' + $this.VARIABLE_END_STRING),($this.variables[$key])
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
            if ($this.TemplateString -match ("{{\s*" + $array.Name + '.' + "\w*\s*}}")) {
                foreach ($key in $array.Array[0].keys) {
                    $Rezult = $Rezult -replace ("{{\s*" + $array.Name + '.' + $key + "\s*}}"), $array.Array[0][$key]
                }
            }
        }
        return $Rezult
    }

    [System.Object]renderFile() {
        $Rezult = @()
        $k = 0
        for ($i = 0; $i -le $this.TemplateArrayString.Count; $i++) {
            $tmp = $this.TemplateArrayString[$i]
            [boolean]$Cycle = $false
            Switch -regex ($tmp) {
                '{{\s*\w+\s*}}' {
                    $this.TemplateString = $tmp
                    $tmp = $this.render()
                }
                '{{\s*\w+\.\w+\s*}}' {
                    $this.TemplateString = $tmp
                    $tmp = $this.renderArray()
                }
                '^\s*{%\s*for\s*\w+\s*in\s*\w+\s*%}\s*$' {
                    $Rezult = $this.ProcessingCycle($Rezult,$i)
                    while ($this.TemplateArrayString[$i] -notmatch '^\s*{%\s*endfor\s*%}\s*$') {
                        $i++
                    }
                    $Cycle = $true
                }
                DEFAULT {
                    $tmp = $this.TemplateArrayString[$i]
                }
            }
            if (!$Cycle) {$Rezult += $tmp}
        }
        return $Rezult
    }

    hidden [System.Object]ProcessingCycle ($Rezult,$i) {
        $tmp = $this.TemplateArrayString[$i] -replace '^\s*{%\s*for\s*'
        $AleasArray = $tmp -replace '\s*in\s*\w+\s*%}\s*$'
        $tmp = $this.TemplateArrayString[$i] -replace '^\s*{%\s*for\s*\w+\s*in\s*'
        $TargetArray = $tmp -replace '\s*%}\s*$'
        $i++
        $StartCycle = $i
        while ($this.TemplateArrayString[$i] -notmatch '^\s*{%\s*endfor\s*%}\s*$') {
            $i++
        }
        $EndCycle = ($i - 1)
        foreach ($array in $this.DataCollection) {
            if ($TargetArray -eq $array.Name) {
                for ($k = 0; $k -lt $array.Array.Count; $k++) {
                    for ($s = $StartCycle; $s -le $EndCycle; $s++) {
                        $tmp = $this.TemplateArrayString[$s]
                        if ($tmp -match ('{{\s*' + $AleasArray + '\.\w+\s*}}')){        
                            foreach ($key in $array.Array[$k].keys) {
                                $tmp = $tmp -replace ('{{\s*' + $AleasArray + '\.' + $key + '\s*}}'),($array.Array[$k][$key])
                            }
                            $Rezult += $tmp
                        } else {
                            switch -regex ($tmp) {
                                '{{\s*\w+\s*}}' {
                                    $this.TemplateString = $tmp
                                    $tmp = $this.render()
                                }
                                '{{\s*\w+\.\w+\s*}}' {
                                    $this.TemplateString = $tmp
                                    $tmp = $this.renderArray()
                                }
                                DEFAULT {
                                    $tmp = $tmp
                                }
                            }
                            $Rezult += $tmp
                        }
                    }
                }
            }
        }
        return $Rezult
    }

    AddVareables ($dictionary){
        if ($dictionary.GetType().Name -eq "Hashtable") {
            $this.variables = $dictionary
        }
    }

    AddArray ([string]$name, [Hashtable]$Array) {
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
            }
            if (!$existArray) {
                $this.DataCollection += $this.CreateNewArray($name,$Array)
            }
        }
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