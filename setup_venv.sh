#!/bin/bash

# Script to set up a Python virtual environment to manage packages
# and avoid the "externally managed environment" error in Kali Linux.
# It also offers a *risky* option for a global bypass of the error,
# and an option to suppress the "Running pip as root" warning.

echo "-------------------------------------------------------------------"
echo "Python Environment Setup Script for Kali Linux (PEP 668 & Root Warning)"
echo "-------------------------------------------------------------------"
echo ""
echo "This script helps you set up a Python virtual environment, which is"
echo "the RECOMMENDED and SAFE way to install Python packages for your"
echo "projects, preventing conflicts with your system's Python installation"
echo "managed by APT. Using virtual environments also naturally avoids the"
echo "'Running pip as root' warning."
echo ""

# --- Step 1: Check and install python3-venv if not present ---
echo "Checking for 'python3-venv' package..."
if ! dpkg -s python3-venv &> /dev/null; then
    echo "'python3-venv' is not installed. Installing it now..."
    sudo apt update
    sudo apt install -y python3-venv
    if [ $? -eq 0 ]; then
        echo "'python3-venv' installed successfully."
    else
        echo "Error: Failed to install 'python3-venv'. Please try installing it manually:"
        echo "  sudo apt install python3-venv"
        exit 1
    fi
else
    echo "'python3-venv' is already installed."
fi

echo ""

# --- Step 2: Virtual Environment Setup (Recommended) ---
echo "--- Virtual Environment Setup (RECOMMENDED) ---"
read -p "Do you want to create a new Python virtual environment for your project? (Y/n): " CREATE_VENV_CHOICE
CREATE_VENV_CHOICE=${CREATE_VENV_CHOICE:-Y} # Default to Yes

if [[ "$CREATE_VENV_CHOICE" =~ ^[Yy]$ ]]; then
    read -p "Enter the desired name for your virtual environment (e.g., 'myproject_env' or 'venv'): " VENV_NAME

    # Default to 'venv' if no name is provided
    if [ -z "$VENV_NAME" ]; then
        VENV_NAME="venv"
        echo "No name provided. Using default name: '$VENV_NAME'"
    fi

    if [ -d "$VENV_NAME" ]; then
        read -p "Directory '$VENV_NAME' already exists. Do you want to remove it and create a new one? (y/N): " CONFIRM_REMOVE
        if [[ "$CONFIRM_REMOVE" =~ ^[Yy]$ ]]; then
            echo "Removing existing '$VENV_NAME' directory..."
            rm -rf "$VENV_NAME"
        else
            echo "Aborting virtual environment creation."
            # Don't exit, allow to proceed to the global fix option if desired
        fi
    fi

    if [ ! -d "$VENV_NAME" ]; then # Only attempt to create if it doesn't exist or was removed
        echo "Creating virtual environment '$VENV_NAME' in the current directory ($(pwd))..."
        python3 -m venv "$VENV_NAME"

        if [ $? -eq 0 ]; then
            echo "Virtual environment '$VENV_NAME' created successfully!"
            echo ""
            echo "-------------------------------------------------------------------"
            echo "To ACTIVATE your virtual environment, run:"
            echo "   source ./$VENV_NAME/bin/activate"
            echo ""
            echo "Once activated, you can install Python packages using 'pip' normally:"
            echo "   pip install your-desired-package"
            echo ""
            echo "These packages will be installed ONLY within '$VENV_NAME' and will NOT"
            echo "conflict with your system's Python packages. You also won't get the"
            echo "'Running pip as root' warning when using 'pip' inside the venv."
            echo ""
            echo "To DEACTIVATE the virtual environment when you're done, simply run:"
            echo "   deactivate"
            echo "-------------------------------------------------------------------"
            echo ""
            read -p "Would you like to activate the new virtual environment now? (y/N): " ACTIVATE_NOW
            if [[ "$ACTIVATE_NOW" =~ ^[Yy]$ ]]; then
                echo "Activating '$VENV_NAME'..."
                source "./$VENV_NAME/bin/activate"
                echo "Virtual environment '$VENV_NAME' is now active."
                echo "You can now use 'pip install' for your project packages."
            else
                echo "Virtual environment not activated. Remember to activate it manually when needed."
            fi
        else
            echo "Error: Failed to create virtual environment '$VENV_NAME'."
            echo "Please check for any error messages above."
        fi
    fi
fi

echo ""
echo "-------------------------------------------------------------------"
echo "--- WARNING: GLOBAL BYPASS OPTIONS (NOT RECOMMENDED) ---"
echo "-------------------------------------------------------------------"
echo "The following options can lead to a BROKEN Kali Linux system."
echo "They are offered for users who understand and accept these risks."
echo "The RECOMMENDED solution is always to use virtual environments."
echo ""

read -p "Do you understand the risks and still want to attempt global bypasses for pip? (y/N): " GLOBAL_BYPASS_CHOICE
GLOBAL_BYPASS_CHOICE=${GLOBAL_BYPASS_CHOICE:-N} # Default to No

if [[ "$GLOBAL_BYPASS_CHOICE" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Attempting to configure pip to globally ignore warnings."
    echo "This will create or modify ~/.config/pip/pip.conf"
    echo "You MAY need to restart your terminal for changes to take effect."
    echo ""

    # Create config directory if it doesn't exist
    mkdir -p ~/.config/pip

    PIP_CONF_FILE="$HOME/.config/pip/pip.conf"
    
    # Ensure [global] section exists
    if ! grep -q "^\[global\]" "$PIP_CONF_FILE" 2>/dev/null; then
        echo -e "\n[global]" >> "$PIP_CONF_FILE"
    fi

    # Add or update break-system-packages
    if grep -q "break-system-packages" "$PIP_CONF_FILE" 2>/dev/null; then
        sed -i '/break-system-packages/c\break-system-packages = true' "$PIP_CONF_FILE"
        echo "Updated 'break-system-packages = true' in $PIP_CONF_FILE"
    else
        sed -i '/^\[global\]/a break-system-packages = true' "$PIP_CONF_FILE"
        echo "Added 'break-system-packages = true' to $PIP_CONF_FILE"
    fi

    echo ""
    read -p "Do you also want to suppress the 'Running pip as root' warning globally? (y/N): " SUPPRESS_ROOT_WARNING
    SUPPRESS_ROOT_WARNING=${SUPPRESS_ROOT_WARNING:-N} # Default to No

    if [[ "$SUPPRESS_ROOT_WARNING" =~ ^[Yy]$ ]]; then
        # Add or update root-user-action
        if grep -q "root-user-action" "$PIP_CONF_FILE" 2>/dev/null; then
            sed -i '/root-user-action/c\root-user-action = ignore' "$PIP_CONF_FILE"
            echo "Updated 'root-user-action = ignore' in $PIP_CONF_FILE"
        else
            sed -i '/^\[global\]/a root-user-action = ignore' "$PIP_CONF_FILE"
            echo "Added 'root-user-action = ignore' to $PIP_CONF_FILE"
        fi
        echo "The 'Running pip as root' warning will now be suppressed."
    else
        echo "The 'Running pip as root' warning will NOT be suppressed globally."
    fi

    echo ""
    echo "-------------------------------------------------------------------"
    echo "WARNING: Global bypasses enabled. Your pip commands *might* now"
    echo "work without these messages, but you are now at a SIGNIFICANT RISK"
    echo "of breaking your Kali Linux installation. Proceed with extreme caution."
    echo "-------------------------------------------------------------------"
else
    echo "Global bypasses not enabled. Sticking to recommended virtual environments."
fi

echo ""
echo "Script finished."
