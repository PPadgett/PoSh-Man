Add-Type -AssemblyName System.Drawing

# Define the game elements
$global:maze = @(
    "############################",
    "#............##............#",
    "#.####.#####.##.#####.####.#",
    "#.####.#####.##.#####.####.#",
    "#..........................#",
    "############################"
)
$global:playerPosition = [System.Drawing.Point]::new(1, 4)
$global:initialPlayerPosition = [System.Drawing.Point]::new(1, 4)
$global:ghostPositions = @([System.Drawing.Point]::new(26,4))
$global:initialGhostPositions = @([System.Drawing.Point]::new(26,4))
$global:playerLives = 3
$global:totalDots = ($global:maze | Select-String -Pattern "\." -AllMatches).Matches.Count
$global:score = 0
$global:directions = @{
    "Left"  = [System.Drawing.Point]::new(-1, 0)
    "Right" = [System.Drawing.Point]::new(1, 0)
    "Up"    = [System.Drawing.Point]::new(0, -1)
    "Down"  = [System.Drawing.Point]::new(0, 1)
}

# Display the maze and game info
function Display-Maze {
    Clear-Host
    for ($i = 0; $i -lt $global:maze.Length; $i++) {
        $line = $global:maze[$i]
        for ($j = 0; $j -lt $line.Length; $j++) {
            $char = $line[$j]
            $color = switch ($char) {
                '#' { 'Gray' }
                '.' { 'Yellow' }
                'C' { 'DarkYellow' }
                'G' { 'Red' }
                default { 'Black' }
            }
            Write-Host $char -NoNewline -ForegroundColor $color
        }
        Write-Host ""
    }
    Write-Host "Lives: $global:playerLives  Score: $global:score" -ForegroundColor Green
    if ($global:playerLives -le 0 -or $global:score -eq $global:totalDots) {
        Write-Host "Game Over!" -ForegroundColor Red
        Exit
    }
}

# Check for collisions
function Check-Collision {
    foreach ($ghost in $global:ghostPositions) {
        if ($ghost -eq $global:playerPosition) {
            # Reset positions
            $global:playerLives--
            $global:playerPosition = $global:initialPlayerPosition
            for ($i = 0; $i -lt $global:ghostPositions.Count; $i++) {
                $global:ghostPositions[$i] = $global:initialGhostPositions[$i]
            }
            # Redraw elements
            Draw-Elements
            if ($global:playerLives -le 0) {
                Display-Maze
            }
        }
    }
}

# Redraw all game elements to their initial positions
function Draw-Elements {
    $global:maze = $global:maze | ForEach-Object {
        $_ -replace 'C', ' ' -replace 'G', ' '
    }
    $global:maze[$global:playerPosition.Y] = $global:maze[$global:playerPosition.Y].Remove($global:playerPosition.X, 1).Insert($global:playerPosition.X, 'C')
    foreach ($ghost in $global:ghostPositions) {
        $global:maze[$ghost.Y] = $global:maze[$ghost.Y].Remove($ghost.X, 1).Insert($ghost.X, 'G')
    }
    Display-Maze
}

# Move the ghosts
function Move-Ghosts {
    for ($i = 0; $i -lt $global:ghostPositions.Count; $i++) {
        $validDirections = $global:directions.GetEnumerator() | Where-Object {
            $newPosition = $global:ghostPositions[$i] + $_.Value
            $global:maze[$newPosition.Y][$newPosition.X] -ne '#'
        }
        if ($validDirections.Count -gt 0) {
            $direction = Get-Random -InputObject $validDirections.Name
            $newPosition = $global:ghostPositions[$i] + $global:directions[$direction]
            $global:ghostPositions[$i] = $newPosition
        }
    }
    Draw-Elements
    Check-Collision
}

# Update the game state
function Move-Pacman {
    param($direction)
    $newPosition = $global:playerPosition + $global:directions[$direction]
    if ($global:maze[$newPosition.Y][$newPosition.X] -ne '#') {
        if ($global:maze[$newPosition.Y][$newPosition.X] -eq '.') {
            $global:score++
        }
        $global:playerPosition = $newPosition
        Move-Ghosts
    }
}

# Main game loop
function Start-Game {
    Display-Maze
    while ($true) {
        if ($host.UI.RawUI.KeyAvailable) {
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            switch ($key.VirtualKeyCode) {
                37 { Move-Pacman -direction "Left" }  # Left arrow
                39 { Move-Pacman -direction "Right" } # Right arrow
                38 { Move-Pacman -direction "Up" }    # Up arrow
                40 { Move-Pacman -direction "Down" }  # Down arrow
            }
            Draw-Elements
        }
        Start-Sleep -Milliseconds 200
    }
}

Start-Game
