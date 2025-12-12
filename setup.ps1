# PowerShell script to check and install requirements for WosBot project
#
# Usage:
#   .\setup.ps1              - Check requirements and offer to install/fix missing ones
#   .\setup.ps1 -AutoInstall - Automatically install/fix everything without prompts
#   .\setup.ps1 -CheckOnly   - Only check requirements, don't offer installation/fixes
#
# This script checks and can install/fix:
#   - Java 21+ installation and version
#   - Maven installation and version
#   - JAVA_HOME environment variable (for IDE integration)
#   - Project structure (modules, pom.xml)
#   - Native libraries (ADB, OpenCV, Tesseract)
#   - Build status (can build project automatically)
#   - VS Code Java extensions (for debugging)

param(
    [switch]$AutoInstall = $false,
    [switch]$CheckOnly = $false
)

$ErrorActionPreference = "Continue"
$requirementsMet = $true
$javaInstalled = $false
$mavenInstalled = $false
$javaNeedsInstall = $false
$mavenNeedsInstall = $false
$javaHomeNeedsSet = $false
$projectNeedsBuild = $false
$vscodeExtensionsNeeded = $false

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WosBot Project Setup & Requirements" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to print status
function Write-Status {
    param(
        [string]$Message,
        [string]$Status,  # "OK", "WARN", "FAIL"
        [string]$Details = ""
    )

    $color = switch ($Status) {
        "OK"   { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
        default { "White" }
    }

    $symbol = switch ($Status) {
        "OK"   { "[OK]" }
        "WARN" { "[!]" }
        "FAIL" { "[X]" }
        default { "[?]" }
    }

    Write-Host "$symbol " -NoNewline -ForegroundColor $color
    Write-Host $Message -NoNewline
    if ($Details) {
        Write-Host " - $Details" -ForegroundColor Gray
    } else {
        Write-Host ""
    }
}

# Function to install Java via Scoop
function Install-Java {
    $scoopPath = "$env:USERPROFILE\scoop\shims\scoop.cmd"
    if (-not (Test-Path $scoopPath)) {
        Write-Status "Scoop not found" "FAIL" "Cannot install Java automatically"
        return $false
    }

    Write-Host "Adding Java bucket..." -ForegroundColor Yellow
    & $scoopPath bucket add java 2>&1 | Out-Null

    Write-Host "Installing Java 21 (Temurin JDK)..." -ForegroundColor Yellow
    & $scoopPath install temurin21-jdk 2>&1 | Out-Host

    if ($LASTEXITCODE -eq 0) {
        Write-Status "Java installed successfully" "OK"
        # Refresh PATH for current session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        return $true
    } else {
        Write-Status "Failed to install Java" "FAIL"
        return $false
    }
}

# Function to install Maven via Scoop
function Install-Maven {
    $scoopPath = "$env:USERPROFILE\scoop\shims\scoop.cmd"
    if (-not (Test-Path $scoopPath)) {
        Write-Status "Scoop not found" "FAIL" "Cannot install Maven automatically"
        return $false
    }

    Write-Host "Installing Maven..." -ForegroundColor Yellow
    & $scoopPath install maven 2>&1 | Out-Host

    if ($LASTEXITCODE -eq 0) {
        Write-Status "Maven installed successfully" "OK"
        # Refresh PATH for current session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        return $true
    } else {
        Write-Status "Failed to install Maven" "FAIL"
        return $false
    }
}

# Function to set JAVA_HOME
function Set-JavaHome {
    # Try to find Java installation
    $javaCmd = "java"
    $scoopJavaPath = "$env:USERPROFILE\scoop\shims\java.cmd"
    if (Test-Path $scoopJavaPath) {
        $javaCmd = $scoopJavaPath
    }

    try {
        # Get Java home from java -XshowSettings:properties
        $javaProps = & $javaCmd -XshowSettings:properties -version 2>&1 | Select-String -Pattern "java.home"
        if ($javaProps -match "java.home\s*=\s*(.+)") {
            $javaHomePath = $matches[1].Trim()

            # Set JAVA_HOME for current session
            $env:JAVA_HOME = $javaHomePath

            # Set JAVA_HOME permanently for user
            [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHomePath, "User")

            Write-Status "JAVA_HOME set successfully" "OK" $javaHomePath
            Write-Host "   Note: Restart terminal for changes to take full effect" -ForegroundColor Gray
            return $true
        } else {
            # Fallback: try to find from Scoop installation
            $scoopJavaDir = "$env:USERPROFILE\scoop\apps\temurin21-jdk\current"
            if (Test-Path $scoopJavaDir) {
                [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $scoopJavaDir, "User")
                $env:JAVA_HOME = $scoopJavaDir
                Write-Status "JAVA_HOME set successfully" "OK" $scoopJavaDir
                Write-Host "   Note: Restart terminal for changes to take full effect" -ForegroundColor Gray
                return $true
            }
        }
    } catch {
        Write-Status "Failed to set JAVA_HOME" "FAIL" $_.Exception.Message
        return $false
    }

    Write-Status "Could not determine Java installation path" "FAIL"
    return $false
}

# Function to build the project
function Build-Project {
    $mvnCmd = "mvn"
    $scoopMavenPath = "$env:USERPROFILE\scoop\shims\mvn.cmd"
    if (Test-Path $scoopMavenPath) {
        $mvnCmd = $scoopMavenPath
    }

    Write-Host "Building project (this may take a few minutes)..." -ForegroundColor Yellow
    Write-Host ""

    Push-Location $projectRoot
    try {
        & $mvnCmd clean install package 2>&1 | Tee-Object -Variable buildOutput

        if ($LASTEXITCODE -eq 0) {
            Write-Status "Project built successfully" "OK"
            return $true
        } else {
            Write-Status "Build failed" "FAIL" "Check output above for errors"
            return $false
        }
    } catch {
        Write-Status "Build failed" "FAIL" $_.Exception.Message
        return $false
    } finally {
        Pop-Location
    }
}

# Function to install VS Code extensions
function Install-VSCodeExtensions {
    $codeCmd = "code"
    $codePath = Get-Command code -ErrorAction SilentlyContinue
    if (-not $codePath) {
        # Try common VS Code installation paths
        $codePaths = @(
            "${env:ProgramFiles}\Microsoft VS Code\bin\code.cmd",
            "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd",
            "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
        )

        foreach ($path in $codePaths) {
            if (Test-Path $path) {
                $codeCmd = $path
                break
            }
        }
    } else {
        $codeCmd = $codePath.Source
    }

    if (-not (Test-Path $codeCmd) -and -not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Status "VS Code not found" "FAIL" "VS Code may not be installed or not in PATH"
        Write-Host "   Install VS Code from: https://code.visualstudio.com/" -ForegroundColor Gray
        Write-Host "   Then install Extension Pack for Java manually from VS Code" -ForegroundColor Gray
        return $false
    }

    Write-Host "Installing VS Code Java Extension Pack..." -ForegroundColor Yellow
    Write-Host "   This will open VS Code if it's not already running" -ForegroundColor Gray
    Write-Host ""

    try {
        # Install Extension Pack for Java (includes all Java extensions)
        & $codeCmd --install-extension vscjava.vscode-java-pack 2>&1 | Out-Host

        if ($LASTEXITCODE -eq 0) {
            Write-Status "VS Code Java Extension Pack installed" "OK"
            Write-Host "   Note: Reload VS Code window for extensions to activate" -ForegroundColor Gray
            return $true
        } else {
            Write-Status "Failed to install VS Code extensions" "FAIL" "Try installing manually from VS Code"
            Write-Host "   Open VS Code and search for: Extension Pack for Java" -ForegroundColor Gray
            return $false
        }
    } catch {
        Write-Status "Failed to install VS Code extensions" "FAIL" $_.Exception.Message
        Write-Host "   Try installing manually: Open VS Code and search for 'Extension Pack for Java'" -ForegroundColor Gray
        return $false
    }
}

# Check Java Installation
Write-Host "1. Checking Java Installation..." -ForegroundColor Yellow
try {
    # Check Scoop shims first (common installation method)
    $scoopJavaPath = "$env:USERPROFILE\scoop\shims\java.cmd"
    $javaCmd = "java"
    if (Test-Path $scoopJavaPath) {
        $javaCmd = $scoopJavaPath
    }

    # Refresh PATH to include Scoop shims
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    $javaVersionOutput = & $javaCmd -version 2>&1
    if ($LASTEXITCODE -eq 0 -or $javaVersionOutput) {
        # Extract version number
        $versionLine = ($javaVersionOutput | Select-String -Pattern "version").ToString()
        if ($versionLine -match '"(\d+)\.(\d+)\.(\d+)[^`"]*"') {
            $majorVersion = [int]$matches[1]
            $minorVersion = [int]$matches[2]

            if ($majorVersion -ge 21) {
                Write-Status "Java installed" "OK" "Version: $majorVersion.$minorVersion (Required: 21+)"
                $javaInstalled = $true
            } elseif ($majorVersion -ge 17) {
                Write-Status "Java installed" "WARN" "Version: $majorVersion.$minorVersion (Recommended: 21, Minimum: 17)"
                $javaInstalled = $true
            } else {
                Write-Status "Java version too old" "FAIL" "Found: $majorVersion.$minorVersion, Required: 21+ (or 17+)"
                $javaNeedsInstall = $true
                $requirementsMet = $false
            }

            # Check JAVA_HOME
            if ($env:JAVA_HOME) {
                Write-Status "JAVA_HOME set" "OK" $env:JAVA_HOME
            } else {
                Write-Status "JAVA_HOME not set" "WARN" "Optional but recommended for IDE integration"
                $javaHomeNeedsSet = $true
            }
        } else {
            Write-Status "Java installed" "OK" "Version check (unable to parse version)"
            $javaInstalled = $true
        }
    } else {
        Write-Status "Java not found" "FAIL" "Java is not in PATH"
        $javaNeedsInstall = $true
        $requirementsMet = $false
    }
} catch {
    Write-Status "Java not found" "FAIL" "Error checking Java: $_"
    $javaNeedsInstall = $true
    $requirementsMet = $false
}
Write-Host ""

# Check Maven Installation
Write-Host "2. Checking Maven Installation..." -ForegroundColor Yellow
try {
    # Check Scoop shims first (common installation method)
    $scoopMavenPath = "$env:USERPROFILE\scoop\shims\mvn.cmd"
    $mvnCmd = "mvn"
    if (Test-Path $scoopMavenPath) {
        $mvnCmd = $scoopMavenPath
    }

    $mavenVersionOutput = & $mvnCmd -version 2>&1
    if ($LASTEXITCODE -eq 0 -or $mavenVersionOutput) {
        $versionLine = ($mavenVersionOutput | Select-String -Pattern "Apache Maven").ToString()
        if ($versionLine -match "Apache Maven (\d+)\.(\d+)\.(\d+)") {
            $majorVersion = [int]$matches[1]
            $minorVersion = [int]$matches[2]
            Write-Status "Maven installed" "OK" "Version: $majorVersion.$minorVersion.$($matches[3])"
            $mavenInstalled = $true
        } else {
            Write-Status "Maven installed" "OK" "Version check (unable to parse version)"
            $mavenInstalled = $true
        }
    } else {
        Write-Status "Maven not found" "FAIL" "Maven is not in PATH"
        $mavenNeedsInstall = $true
        $requirementsMet = $false
    }
} catch {
    Write-Status "Maven not found" "FAIL" "Error checking Maven: $_"
    $mavenNeedsInstall = $true
    $requirementsMet = $false
}
Write-Host ""

# Check Project Structure
Write-Host "3. Checking Project Structure..." -ForegroundColor Yellow
$projectRoot = $PSScriptRoot
if (-not $projectRoot) {
    $projectRoot = Get-Location
}

# Check pom.xml
if (Test-Path "$projectRoot\pom.xml") {
    Write-Status "Project root found" "OK" "pom.xml exists"
} else {
    Write-Status "Project root not found" "FAIL" "pom.xml missing"
    $requirementsMet = $false
}

# Check modules
$modules = @("wos-hmi", "wos-utiles", "wos-persitence", "wos-serv", "wos-ot")
foreach ($module in $modules) {
    if (Test-Path "$projectRoot\$module\pom.xml") {
        Write-Status "Module '$module' found" "OK"
    } else {
        Write-Status "Module '$module' missing" "FAIL"
        $requirementsMet = $false
    }
}
Write-Host ""

# Check Native Libraries
Write-Host "4. Checking Native Libraries..." -ForegroundColor Yellow
$libPath = "$projectRoot\lib"

if (Test-Path $libPath) {
    Write-Status "lib directory found" "OK"

    # Check ADB
    if (Test-Path "$libPath\adb\adb.exe") {
        Write-Status "ADB executable found" "OK"
    } else {
        Write-Status "ADB executable missing" "WARN" "Required for emulator control"
    }

    # Check OpenCV
    if (Test-Path "$libPath\opencv\opencv_java4110.dll") {
        Write-Status "OpenCV library found" "OK"
    } else {
        Write-Status "OpenCV library missing" "WARN" "Required for image processing"
    }

    # Check Tesseract
    if (Test-Path "$libPath\tesseract\eng.traineddata") {
        Write-Status "Tesseract data found" "OK"
    } else {
        Write-Status "Tesseract data missing" "WARN" "Required for OCR"
    }
} else {
    Write-Status "lib directory not found" "WARN" "Native libraries may be missing"
}
Write-Host ""

# Check Build Status
Write-Host "5. Checking Build Status..." -ForegroundColor Yellow
$targetPath = "$projectRoot\wos-hmi\target"
$libTargetPath = "$targetPath\lib"

if (Test-Path $targetPath) {
    Write-Status "Build directory exists" "OK"

    if (Test-Path $libTargetPath) {
        $jarCount = (Get-ChildItem -Path $libTargetPath -Filter "*.jar" -ErrorAction SilentlyContinue).Count
        if ($jarCount -gt 0) {
            Write-Status "Dependencies copied" "OK" "$jarCount JAR files found"
        } else {
            Write-Status "Dependencies not found" "WARN" "Run 'mvn clean install package' to build"
            $projectNeedsBuild = $true
        }
    } else {
        Write-Status "Dependencies not built" "WARN" "Run 'mvn clean install package' to build"
        $projectNeedsBuild = $true
    }

    # Check for JAR file
    $jarFiles = Get-ChildItem -Path $targetPath -Filter "wos-bot-*.jar" -ErrorAction SilentlyContinue
    if ($jarFiles) {
        Write-Status "Application JAR found" "OK" $jarFiles[0].Name
    } else {
        Write-Status "Application JAR not found" "WARN" "Run 'mvn clean install package' to build"
        $projectNeedsBuild = $true
    }
} else {
    Write-Status "Project not built" "WARN" "Run 'mvn clean install package' to build"
    $projectNeedsBuild = $true
}
Write-Host ""

# Check VS Code Java Extension (optional)
Write-Host "6. Checking VS Code Setup (Optional)..." -ForegroundColor Yellow
$vscodeExtensionsPath = "$env:USERPROFILE\.vscode\extensions"
if (Test-Path $vscodeExtensionsPath) {
    $javaExtensions = Get-ChildItem -Path $vscodeExtensionsPath -Filter "*java*" -Directory -ErrorAction SilentlyContinue
    if ($javaExtensions) {
        Write-Status "VS Code Java extensions found" "OK" "$($javaExtensions.Count) extension(s)"
    } else {
        Write-Status "VS Code Java extensions not found" "WARN" "Install Extension Pack for Java for debugging"
        $vscodeExtensionsNeeded = $true
    }
} else {
    Write-Status "VS Code extensions directory not found" "WARN" "VS Code may not be installed"
}

# Check launch.json
if (Test-Path "$projectRoot\.vscode\launch.json") {
    Write-Status "Debug configuration found" "OK" ".vscode/launch.json exists"
} else {
    Write-Status "Debug configuration missing" "WARN" "Debug configuration not found"
}
Write-Host ""

# Action section - handle installations and fixes
$hasActions = $javaNeedsInstall -or $mavenNeedsInstall -or $javaHomeNeedsSet -or $projectNeedsBuild -or $vscodeExtensionsNeeded

if ((-not $CheckOnly) -and $hasActions) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Installation Options" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $scoopPath = "$env:USERPROFILE\scoop\shims\scoop.cmd"
    $scoopAvailable = Test-Path $scoopPath

    if (-not $scoopAvailable) {
        Write-Host "[!] Scoop is not installed. Cannot auto-install." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To install Scoop:" -ForegroundColor Cyan
        Write-Host "  1. Open PowerShell as Administrator" -ForegroundColor White
        Write-Host "  2. Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
        Write-Host "  3. Run: irm get.scoop.sh | iex" -ForegroundColor White
        Write-Host ""
        Write-Host "Or install manually:" -ForegroundColor Cyan
        if ($javaNeedsInstall) {
            Write-Host "  Java: https://adoptium.net/" -ForegroundColor White
        }
        if ($mavenNeedsInstall) {
            Write-Host "  Maven: https://maven.apache.org/install.html" -ForegroundColor White
        }
        Write-Host ""
    } else {
        if ($AutoInstall) {
            Write-Host "Auto-install mode: Installing missing requirements and fixing warnings..." -ForegroundColor Yellow
            Write-Host ""

            if ($javaNeedsInstall) {
                if (Install-Java) {
                    $javaInstalled = $true
                    $javaNeedsInstall = $false
                }
                Write-Host ""
            }

            if ($mavenNeedsInstall) {
                if (Install-Maven) {
                    $mavenInstalled = $true
                    $mavenNeedsInstall = $false
                }
                Write-Host ""
            }

            if ($javaHomeNeedsSet -and $javaInstalled) {
                Set-JavaHome | Out-Null
                Write-Host ""
            }

            if ($projectNeedsBuild -and $javaInstalled -and $mavenInstalled) {
                Build-Project | Out-Null
                Write-Host ""
            }

            if ($vscodeExtensionsNeeded) {
                Install-VSCodeExtensions | Out-Null
                Write-Host ""
            }

            # Re-check if installation was successful
            if ($javaInstalled -and $mavenInstalled) {
                $requirementsMet = $true
            }
        } else {
            Write-Host "Missing requirements and optional fixes detected:" -ForegroundColor Yellow
            Write-Host ""

            if ($javaNeedsInstall) {
                Write-Host "  [ ] Java 21 (Temurin JDK) - Required" -ForegroundColor White
            }
            if ($mavenNeedsInstall) {
                Write-Host "  [ ] Maven - Required" -ForegroundColor White
            }
            if ($javaHomeNeedsSet) {
                Write-Host "  [ ] Set JAVA_HOME - Recommended for IDE" -ForegroundColor Cyan
            }
            if ($projectNeedsBuild) {
                Write-Host "  [ ] Build project - Recommended" -ForegroundColor Cyan
            }
            if ($vscodeExtensionsNeeded) {
                Write-Host "  [ ] Install VS Code Java extensions - Optional" -ForegroundColor Cyan
            }
            Write-Host ""

            $response = Read-Host "Would you like to install/fix these? (Y/N)"
            if ($response -eq 'Y' -or $response -eq 'y') {
                Write-Host ""

                if ($javaNeedsInstall) {
                    if (Install-Java) {
                        $javaInstalled = $true
                        $javaNeedsInstall = $false
                    }
                    Write-Host ""
                }

                if ($mavenNeedsInstall) {
                    if (Install-Maven) {
                        $mavenInstalled = $true
                        $mavenNeedsInstall = $false
                    }
                    Write-Host ""
                }

                if ($javaHomeNeedsSet -and $javaInstalled) {
                    Write-Host "Setting JAVA_HOME..." -ForegroundColor Yellow
                    Set-JavaHome | Out-Null
                    Write-Host ""
                }

                if ($projectNeedsBuild -and $javaInstalled -and $mavenInstalled) {
                    $buildResponse = Read-Host "Build the project now? This may take a few minutes (Y/N)"
                    if ($buildResponse -eq 'Y' -or $buildResponse -eq 'y') {
                        Build-Project | Out-Null
                        Write-Host ""
                    }
                }

                if ($vscodeExtensionsNeeded) {
                    $extResponse = Read-Host "Install VS Code Java Extension Pack? (Y/N)"
                    if ($extResponse -eq 'Y' -or $extResponse -eq 'y') {
                        Install-VSCodeExtensions | Out-Null
                        Write-Host ""
                    }
                }

                # Re-check if installation was successful
                if ($javaInstalled -and $mavenInstalled) {
                    $requirementsMet = $true
                }
            }
        }
    }
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($requirementsMet) {
    Write-Host "[OK] All critical requirements met!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Build the project: mvn clean install package" -ForegroundColor White
    Write-Host "  2. Run in VS Code: Press F5 to start debugging" -ForegroundColor White
    Write-Host "  3. Or run JAR: java -jar wos-hmi\target\wos-bot-*.jar" -ForegroundColor White
} else {
    Write-Host "[X] Some requirements are missing!" -ForegroundColor Red
    Write-Host ""
    if ($javaNeedsInstall -or $mavenNeedsInstall) {
        Write-Host "To install missing requirements:" -ForegroundColor Yellow
        Write-Host "  - Run with auto-install: .\setup.ps1 -AutoInstall" -ForegroundColor White
        Write-Host "  - Or install via Scoop manually:" -ForegroundColor White
        if ($javaNeedsInstall) {
            Write-Host "    scoop install temurin21-jdk" -ForegroundColor Gray
        }
        if ($mavenNeedsInstall) {
            Write-Host "    scoop install maven" -ForegroundColor Gray
        }
        Write-Host "  - Or download manually:" -ForegroundColor White
        if ($javaNeedsInstall) {
            Write-Host "    Java: https://adoptium.net/" -ForegroundColor Gray
        }
        if ($mavenNeedsInstall) {
            Write-Host "    Maven: https://maven.apache.org/install.html" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "After installation, restart terminal and run this script again." -ForegroundColor Yellow
    } else {
        Write-Host "Please address the issues above and run this script again." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Script completed." -ForegroundColor Gray

# Return exit code
if ($requirementsMet) {
    exit 0
} else {
    exit 1
}

