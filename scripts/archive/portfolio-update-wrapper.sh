#!/bin/bash
###############################################################################
# Portfolio Update Wrapper - Can be called from anywhere
# Usage: portfolio-update (when installed in PATH)
###############################################################################

PROJECT_DIR="/home/goce/Desktop/Cursor projects/Pi-version-control"

# Run the make command from the project directory
cd "$PROJECT_DIR" && make portfolio-update

