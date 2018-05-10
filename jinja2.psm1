class Enveroment 
{
    [string]$BLOCK_START_STRING = '{%'
    [string]$BLOCK_END_STRING = '%}'
    [string]$VARIABLE_START_STRING = '{{'
    [string]$VARIABLE_END_STRING = '}}'
    [string]$COMMENT_START_STRING = '{#'
    [string]$COMMENT_END_STRING = '#}'
    [string]$PATTERN_STRING_ARRAY = ($this.VARIABLE_START_STRING + '\s*(\w+)\.(\w+)\s*' + $this.VARIABLE_END_STRING)
    [string]$PATTERN_VARIABLE = ($this.VARIABLE_START_STRING + '\s*(\w+)\s*' + $this.VARIABLE_END_STRING)
    [string]$PATTERN_START_CYCLE = ('^\s*' + $this.BLOCK_START_STRING + '\s*for\s+(\w+)\s+in\s+(\w+)\s*' + $this.BLOCK_END_STRING + '\s*$')
    [string]$PATTERN_END_CYCLE = ('^\s*' + $this.BLOCK_START_STRING + '\s*endfor\s*' + $this.BLOCK_END_STRING + '\s*$')
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

    SetDataCollection ($UserDataCollection) {
        if(!$UserDataCollection){
            return
        }
        $this.DataCollection = ConvertFrom-Yaml $UserDataCollection
    }

    [string]render ([string]$String) {
            DO {
                $ValueName = $String -replace ('^.*' + $this.PATTERN_VARIABLE + '.*$'), '$1'
                if ($this.DataCollection.keys -match $ValueName) {
                    $String = $String -replace ('{{\s*' + $ValueName + '\s*}}'), $this.DataCollection[$ValueName]
                }
            } while ($String -match $this.PATTERN_VARIABLE)
        return $String
    }

    hidden [string]renderArray($String) {
        DO {
            $ExistVariable = $true
            $ArrayName = $String -replace ('^.*' + $this.PATTERN_STRING_ARRAY + '.*$'), '$1'
            $ValueName = $String -replace ('^.*' + $this.PATTERN_STRING_ARRAY + '.*$'), '$2'
            if ($this.DataCollection.Keys -match $ArrayName) {
                if ($this.DataCollection[$ArrayName].Keys -match $ValueName) {
                    $String = $String -replace ("{{\s*" + $ArrayName + '.' + $ValueName + "\s*}}"), $this.DataCollection[$ArrayName][0][$ValueName]
                } else {
                    $ExistVariable = $false
                }
            } else {
                $ExistVariable = $false
            }
        } while (($String -match $this.PATTERN_STRING_ARRAY) -and $ExistVariable)
        return $String
    }

    [System.Object]renderFile() {
        $Rezult = @()
        $k = 0
        for ($i = 0; $i -le $this.TemplateArrayString.Count; $i++) {
            $tmp = $this.TemplateArrayString[$i]
            [boolean]$Skip = $false
            Switch -regex ($tmp) {
                $this.PATTERN_VARIABLE {
                    $tmp = $this.render($tmp)
                }
                $this.PATTERN_STRING_ARRAY {
                    $tmp = $this.renderArray($tmp)
                }
                $this.PATTERN_START_CYCLE {
                    $Rezult = $this.ProcessingCycle($Rezult,$i)
                    while ($this.TemplateArrayString[$i] -notmatch $this.PATTERN_END_CYCLE) {
                        $i++
                    }
                    $Skip = $true
                }
                '{%\s*if.*%}' {
                    if ($this.TestIf($tmp)) {
                        $tmp = $tmp -replace '{%\s*if.*%}','TRUE'
                    } else {
                        while ($this.TemplateArrayString[$i] -notmatch '^\s*{%\s*endif\s*%}\s*$') {
                            $i++
                        }
                    }
                    $Skip = $true
                }
                '{%\s*endif\s*%}'{
                    $Skip = $true
                }
                DEFAULT {
                    $tmp = $this.TemplateArrayString[$i]
                }
            }
            if (!$Skip) {$Rezult += $tmp}
        }
        return $Rezult
    }

    hidden [boolean]TestIf ($ifVariable) {
        [boolean]$rezTestIf = $false
        switch -regex ($ifVariable) {
            '{%\s*if\s+\w+\.*\w*\s*%}' {
                $keyVariable = $ifVariable
                $keyVariable = $keyVariable -replace '\s*{%\s*if\s+'
                $keyVariable = $keyVariable -replace '\s*%}\s*'
                if ($keyVariable -match "\.") {
                    $arrayName = ($keyVariable -replace '\.\w+$','')
                    $arrayKey = ($keyVariable -replace '^\w+\.','')
                    foreach ($array in $this.DataCollection) {
                        if ($array.Name -eq $arrayName) {
                            foreach ($key in $array.Array.Keys) {
                                if ($key -eq $arrayKey) {
                                    $rezTestIf = $true
                                    break
                                }
                            }
                            break
                        }
                    }
                } else {
                    foreach ($key in $this.variables.keys) {
                        if ($key -eq $keyVariable) {
                            $rezTestIf = $true
                            break
                        }
                    }
                    if (!$rezTestIf) {
                        foreach ($array in $this.DataCollection) {
                            if ($array.Name -eq $keyVariable) {
                                $rezTestIf = $true
                                break
                            }
                        }
                    }
                }
            }
            DEFAULT {
                $rezTestIf = $false
            }
        }
        return $rezTestIf
    }

    hidden [System.Object]ProcessingCycle ($Rezult,$i) {
        $String= ''
        $AleasArray = $this.TemplateArrayString[$i] -replace $this.PATTERN_START_CYCLE, '$1' #Получаем алиас имени массива
        $TargetArray = $this.TemplateArrayString[$i] -replace $this.PATTERN_START_CYCLE, '$2' #Получаем само имя массива
        if ($this.DataCollection.Keys -match $TargetArray) {
            for ($k = 0; $k -lt $this.DataCollection[$TargetArray].Count; $k++) { #Выполняем цикл столько раз, сколько в массиве элементов
                $s = ($i+1)
                while ($this.TemplateArrayString[$s] -notmatch $this.PATTERN_END_CYCLE) { #Выполняем замену элементов пока не уткнемся в строку завершения цикла
                    $String = $this.TemplateArrayString[$s]
                    switch -regex ($String) {
                        $this.PATTERN_VARIABLE {
                            $String = $this.render($String)
                        }
                        $this.PATTERN_STRING_ARRAY {
                            DO {
                                $valueName = $String -replace ('^.*' + $this.PATTERN_STRING_ARRAY + '.*$'), '$2'
                                if ($String -match ('{{\s*' + $AleasArray + '\.')) {
                                    if ($this.DataCollection[$TargetArray].Keys -match $valueName) {
                                        $String = $String -replace ('{{\s*' + $AleasArray + '\.' + $valueName + '\s*}}'), $this.DataCollection[$TargetArray][$k][$valueName]
                                    }
                                } else {
                                    $String = $this.renderArray($String)
                                }
                            } while ($String -match $this.PATTERN_STRING_ARRAY)
                        }
                    }
                    $s++
                    $Rezult += $String
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