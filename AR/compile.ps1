$matrix = (get-content $PSScriptRoot\matrix2.csv) | ConvertFrom-Csv -Delimiter ';'
$header = ((Get-Content -Path $PSScriptRoot\matrix2.csv | Select-Object -First 1) -split ";").Trim("`"")

$output = @()
$id = 0

foreach ($m in $matrix) {
    $header = $m.PSObject.Properties.Name


    if ($m.LV.ToLower() -match "semester" -or $m.LV -eq "") {
        continue
    }
    # $indexFirstSpace = $m.LV.IndexOf(' ')[0] + 1
    # $length = $m.LV.Length
    $lvs = @{
        LV           = $m.LV#.Substring($indexFirstSpace, $length - $indexFirstSpace)
        id           = $id
        dependencies = @()
        group=$m.LV#.Substring(0,$indexFirstSpace-1)
    }
    foreach ($h in $header) {
        if ($h -eq "LV") { continue }

        # $slimIndexFirstSpace = $h.IndexOf(' ')[0] + 1
        $slimHeader = $h#.Substring($slimIndexFirstSpace, $h.Length - $slimIndexFirstSpace)

        if($slimHeader.Contains("Laufendes Berufspraktikum im Unternehmen")){
            $sdf
        }
        if ($m.$h -eq "x") {
            $lvs.dependencies += $slimHeader
        }
    }
    $output += $lvs
    $id++
}

$nodes = @()
$edges = @()
foreach ($out in $output) {
    $group = $out.group.Split('.')[0]
    $nodes += @{
        id    = $out.LV
        group = $group
    }

    foreach ($dependency in $out.dependencies) {
        $dep = $output | Where-Object { $_.LV -eq $dependency }
        if ($dep -is [array]){$dep = $dep[0]}

        if($group -eq "2" -and $dep.LV.Contains("Laufendes Berufspraktikum im Unternehmen")){
            $sdf
        }

        $edges += @{
            source = $out.LV
            target = $dep.LV
            value  = $group -as [int]
        }
    }
}

$outputObject = @{
    nodes = $nodes
    links = $edges
}
$outputObject | ConvertTo-Json | Out-File $PSScriptRoot\data.json

$tag = "ar8"
docker build --tag container.kandreas.work/matrix:$tag $PSScriptRoot
docker push container.kandreas.work/matrix:$tag