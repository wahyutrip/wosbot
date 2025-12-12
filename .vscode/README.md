# Cursor/VS Code Configuration for WoS Bot

This directory contains configuration files for running and debugging the WoS Bot project in Cursor IDE (or VS Code).

## 📖 Complete Guide

**👉 For complete setup, running, and debugging instructions, see [agents/README.md](../agents/README.md)**

## Configuration Files

- **`launch.json`** - Debug configurations for running the application
- **`tasks.json`** - Build tasks (Maven commands, PowerShell)
- **`settings.json`** - Java and project settings (PowerShell as default terminal)
- **`extensions.json`** - Recommended VS Code extensions

## Quick Reference

### Build Project
```powershell
mvn clean install package
```

### Run/Debug
Press **F5** or use Run and Debug panel → Select **"Debug WoS Bot"**

### Verify Setup
```powershell
.\verify-setup.ps1
```

## Additional Resources

- **Complete Guide**: See [agents/README.md](../agents/README.md) for detailed instructions
- **Project Documentation**: See `agents\` directory
- **Development Guide**: `agents\05-development-guide.md`
- **Architecture**: `agents\01-architecture-overview.md`
