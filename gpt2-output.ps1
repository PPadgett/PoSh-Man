function Invoke-PacMan {
    [CmdletBinding()]
    param (
        [int]$GridWidth = 20,
        [int]$GridHeight = 10,
        [string]$PacManSymbol = 'P',
        [string]$GhostSymbol = 'G',
        [string]$WallSymbol = '#',
        [string]$EmptySpaceSymbol = '.',
        [string]$FoodSymbol = '*'
    )

    # Initialize the grid
    $grid = @()
    for ($y = 0; $y -lt $GridHeight; $y++) {
        $grid += ,(@($EmptySpaceSymbol) * $GridWidth)
    }

    # Create walls (borders)
    for ($x = 0; $x -lt $GridWidth; $x++) {
        $grid[0][$x] = $WallSymbol
        $grid[$GridHeight - 1][$x] = $WallSymbol
    }
    for ($y = 0; $y -lt $GridHeight; $y++) {
        $grid[$y][0] = $WallSymbol
        $grid[$y][$GridWidth - 1] = $WallSymbol
    }

    # Place Pac-Man and a Ghost
    $pacManPos = [PSCustomObject]@{ X = 1; Y = 1 }
    $ghostPos = [PSCustomObject]@{ X = $GridWidth - 2; Y = $GridHeight - 2 }
    $grid[$pacManPos.Y][$pacManPos.X] = $PacManSymbol
    $grid[$ghostPos.Y][$ghostPos.X] = $GhostSymbol

    # Place Food
    $foodPositions = @()
    for ($i = 0; $i -lt 10; $i++) {
        do {
            $foodPos = [PSCustomObject]@{ X = Get-Random -Minimum 1 -Maximum ($GridWidth - 1); Y = Get-Random -Minimum 1 -Maximum ($GridHeight - 1) }
        } while ($grid[$foodPos.Y][$foodPos.X] -ne $EmptySpaceSymbol)
        $grid[$foodPos.Y][$foodPos.X] = $FoodSymbol
        $foodPositions += $foodPos
    }

    function Render-Grid {
        param (
            [array]$Grid
        )
        Clear-Host
        foreach ($row in $Grid) {
            Write-Host ($row -join '') -ForegroundColor Green
        }
    }

    function Move-Entity {
        param (
            [PSCustomObject]$Entity,
            [string]$Direction
        )
        $newPos = [PSCustomObject]@{ X = $Entity.X; Y = $Entity.Y }
        switch ($Direction) {
            'Up' { $newPos.Y-- }
            'Down' { $newPos.Y++ }
            'Left' { $newPos.X-- }
            'Right' { $newPos.X++ }
        }

        if ($grid[$newPos.Y][$newPos.X] -ne $WallSymbol) {
            $grid[$Entity.Y][$Entity.X] = $EmptySpaceSymbol
            $Entity.X = $newPos.X
            $Entity.Y = $newPos.Y
        }
    }

    function Check-Collision {
        param (
            [PSCustomObject]$Entity1,
            [PSCustomObject]$Entity2
        )
        return ($Entity1.X -eq $Entity2.X -and $Entity1.Y -eq $Entity2.Y)
    }

    $directionMap = @{
        'W' = 'Up'
        'S' = 'Down'
        'A' = 'Left'
        'D' = 'Right'
    }

    function Get-UserInput {
        param (
            [hashtable]$DirectionMap
        )
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character.ToUpper()
            if ($DirectionMap.ContainsKey($key)) {
                return $DirectionMap[$key]
            }
        }
        return $null
    }

    function Move-Ghost {
        param (
            [PSCustomObject]$Ghost,
            [PSCustomObject]$PacMan
        )
        $possibleMoves = @()

        if ($grid[$Ghost.Y - 1][$Ghost.X] -ne $WallSymbol) {
            $possibleMoves += [PSCustomObject]@{ X = $Ghost.X; Y = $Ghost.Y - 1; Direction = 'Up' }
        }
        if ($grid[$Ghost.Y + 1][$Ghost.X] -ne $WallSymbol) {
            $possibleMoves += [PSCustomObject]@{ X = $Ghost.X; Y = $Ghost.Y + 1; Direction = 'Down' }
        }
        if ($grid[$Ghost.Y][$Ghost.X - 1] -ne $WallSymbol) {
            $possibleMoves += [PSCustomObject]@{ X = $Ghost.X - 1; Y = $Ghost.Y; Direction = 'Left' }
        }
        if ($grid[$Ghost.Y][$Ghost.X + 1] -ne $WallSymbol) {
            $possibleMoves += [PSCustomObject]@{ X = $Ghost.X + 1; Y = $Ghost.Y; Direction = 'Right' }
        }

        # Select the move that minimizes the distance to Pac-Man
        $bestMove = $possibleMoves |
            Sort-Object { [math]::Abs($_.X - $PacMan.X) + [math]::Abs($_.Y - $PacMan.Y) } |
            Select-Object -First 1

        if ($bestMove) {
            Move-Entity -Entity $Ghost -Direction $bestMove.Direction
        }
    }

    function Check-Food {
        param (
            [PSCustomObject]$PacMan
        )
        $foodPos = $foodPositions |
            Where-Object { $_.X -eq $PacMan.X -and $_.Y -eq $PacMan.Y }

        if ($foodPos) {
            $foodPositions = $foodPositions | Where-Object { $_ -ne $foodPos }
            return $true
        }

        return $false
    }

    # Main game loop
    $score = 0
    do {
        Move-Ghost -Ghost $ghostPos -PacMan $pacManPos
        $input = Get-UserInput -DirectionMap $directionMap
        if ($input) {
            Move-Entity -Entity $pacManPos -Direction $input
        }
        if (Check-Food -PacMan $pacManPos) {
            $score++
        }
        $grid[$pacManPos.Y][$pacManPos.X] = $PacManSymbol
        $grid[$ghostPos.Y][$ghostPos.X] = $GhostSymbol
        Render-Grid -Grid $grid
        Write-Host "Score: $score" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 300
    } while (-not (Check-Collision -Entity1 $pacManPos -Entity2 $ghostPos))

    Write-Host "Game Over! Final Score: $score" -ForegroundColor Red
}

Invoke-PacMan