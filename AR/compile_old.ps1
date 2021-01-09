$matrix = (get-content $PSScriptRoot\matrix2.csv) | ConvertFrom-Csv -Delimiter ';'
$header = ((Get-Content -Path $PSScriptRoot\matrix2.csv | select -First 1) -split ";").Trim("`"")

$output = @()
$id = 0

foreach($m in $matrix){
    $header = $m.PSObject.Properties.Name
    if($m.LV.ToLower() -match "semester" -or $m.LV -eq ""){
        continue
    }
    $indexFirstSpace = $m.LV.IndexOf(' ')[0]
    $length = $m.LV.Length
    $lvs = @{
        LV=$m.LV.Substring($indexFirstSpace,$length-$indexFirstSpace)
        id = $id
        dependencies=@()
    }
    foreach($h in $header){
        if($h -eq "LV"){continue}

        if($m.$h -eq "x"){
            $lvs.dependencies+=$h
        }
    }
    $output+=$lvs
    $id++
}

$nodes = @()
$edges = @()
foreach($out in $output){
    # { id: 0, label: "Berufspraktikum", group: 1 },
    $group = $out.LV.Split('.')[0]
    # $nodes += "{ id: $($out.id), label: `"$($out.LV)`", group: $group},"
    $nodes += @{
        id=$out.LV
        group = $group
    }

    foreach($dependency in $out.dependencies){
        #{ from: 1, to: 3 }
        $dep = $output | where {$_.LV -eq $dependency}
        # $edges += "{ from: $($out.id), to: $($dep.id)},"
        $edges += @{
            source=$out.LV
            target=$dep.LV
            value = $group
        }
    }
}

# ((Get-Content -path $PSScriptRoot\index_template.html -Raw) -replace '<nodes>',$nodes) | Set-Content -Path $PSScriptRoot\index.html
# ((Get-Content -path $PSScriptRoot\index.html -Raw) -replace '<edges>',$edges) | Set-Content -Path $PSScriptRoot\index.html

$outputObject = @{
    nodes = $nodes
    links = $edges
}
$outputObject | ConvertTo-Json |Out-File $PSScriptRoot\data.json

$tag = "ar7"
docker build --tag container.kandreas.work/matrix:$tag $PSScriptRoot
docker push container.kandreas.work/matrix:$tag