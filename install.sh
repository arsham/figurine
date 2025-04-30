#!/bin/bash

# Enable strict mode
set -e         # Exit immediately if a command fails
set -o pipefail # Pipeline fails if any command fails
set -u         # Treat unset variables as errors

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Variables
INSTALL_DIR="/usr/local/bin"
WINDOWS_INSTALL_DIR="$HOME/bin"
TEMP_DIR=$(mktemp -d)
RELEASE_TAG=""
OS=""
ARCH=""
BINARY_NAME="figurine"
GITHUB_REPO=""
LATEST_RELEASE_URL=""
CUSTOM_REPO=""

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      --repo)
        CUSTOM_REPO="$2"
        shift # past argument
        shift # past value
        ;;
      --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --repo OWNER/REPO    Specify a GitHub repository (e.g., arsham/figurine)"
        echo "  --help               Show this help message"
        exit 0
        ;;
      *)
        # Unknown option
        echo -e "${YELLOW}Warning: Unknown option $1${NC}"
        shift
        ;;
    esac
  done
}

# Function to print banner
print_banner() {
  echo -e "${GREEN}"
  echo "==============================================="
  echo -e "        ${BOLD}Figurine Installer${NC}${GREEN}"
  echo "==============================================="
  echo -e "${NC}"
}

# Get repo information dynamically if possible, otherwise use default
get_repo_info() {
  # If a custom repo was specified, use it
  if [ -n "$CUSTOM_REPO" ]; then
    # Parse the owner/repo format
    if [[ "$CUSTOM_REPO" =~ ^([^/]+)/([^/]+)$ ]]; then
      local owner=${BASH_REMATCH[1]}
      local repo=${BASH_REMATCH[2]}
      GITHUB_REPO="https://github.com/$owner/$repo"
      LATEST_RELEASE_URL="https://api.github.com/repos/$owner/$repo/releases/latest"
      echo -e "${BLUE}Using specified repository: $GITHUB_REPO${NC}"
      return
    else
      echo -e "${YELLOW}Invalid repository format. Using git detection or defaults.${NC}"
    fi
  fi

  # Change to the script's directory to ensure .git is found if it exists
  local script_dir
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  cd "$script_dir" 2>/dev/null || true
  
  if command -v git &> /dev/null && [ -d .git ]; then
    # Get remote origin URL
    local remote_url=$(git config --get remote.origin.url)
    # Parse GitHub URL to extract owner and repo
    # Handle SSH format (git@github.com:owner/repo.git) or HTTPS format (https://github.com/owner/repo.git)
    if [[ "$remote_url" =~ github.com[:\/](.+)\/(.+)\.git$ ]]; then
      local owner=${BASH_REMATCH[1]}
      local repo=${BASH_REMATCH[2]}
      GITHUB_REPO="https://github.com/$owner/$repo"
      LATEST_RELEASE_URL="https://api.github.com/repos/$owner/$repo/releases/latest"
      echo -e "${BLUE}Detected repository: $GITHUB_REPO${NC}"
    else
      # Use defaults if parsing fails
      use_default_repo
    fi
  else
    # Not in a git repo, use defaults
    use_default_repo
  fi
}

# Use default repository settings if dynamic detection fails
use_default_repo() {
  local default_owner="arsham"
  local default_repo="figurine"
  GITHUB_REPO="https://github.com/$default_owner/$default_repo"
  LATEST_RELEASE_URL="https://api.github.com/repos/$default_owner/$default_repo/releases/latest"
  echo -e "${YELLOW}Using default repository: $GITHUB_REPO${NC}"
}

# Function to clean up temporary files
cleanup() {
  echo -e "${BLUE}Cleaning up temporary files...${NC}"
  rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

# Function to detect OS and architecture
detect_platform() {
  echo -e "${BLUE}Detecting platform...${NC}"
  
  # Detect OS
  case "$(uname -s)" in
    Linux*)     OS="linux";;
    Darwin*)    OS="darwin";; # macOS
    CYGWIN*|MINGW*|MSYS*) OS="windows";;
    *)          echo -e "${RED}Unsupported OS. Please install manually.${NC}"; exit 1;;
  esac
  
  # Detect architecture
  local arch=$(uname -m)
  case "$arch" in
    x86_64|amd64)  ARCH="amd64";;
    arm64|aarch64) ARCH="arm64";;
    *)             echo -e "${RED}Unsupported architecture: $arch. Please install manually.${NC}"; exit 1;;
  esac
  
  echo -e "${GREEN}Detected: $OS/$ARCH${NC}"
}

# Get latest release information
get_latest_release() {
  echo -e "${BLUE}Fetching latest release information...${NC}"
  
  # Initialize RELEASE_INFO as empty
  RELEASE_INFO=""
  
  # Try to get release info with proper error handling
  if command -v curl &> /dev/null; then
    # Use -f to make curl exit with non-zero status on HTTP errors
    RELEASE_INFO=$(curl -s -f "$LATEST_RELEASE_URL" || echo "")
    if [ -z "$RELEASE_INFO" ]; then
      echo -e "${RED}Error: Failed to fetch release info from $LATEST_RELEASE_URL${NC}"
      exit 1
    fi
  elif command -v wget &> /dev/null; then
    # Use --spider first to check if URL exists
    if ! wget --spider -q "$LATEST_RELEASE_URL"; then
      echo -e "${RED}Error: Failed to fetch release info from $LATEST_RELEASE_URL${NC}"
      exit 1
    fi
    RELEASE_INFO=$(wget -q -O - "$LATEST_RELEASE_URL")
  else
    echo -e "${RED}Error: curl or wget is required but not installed.${NC}"
    exit 1
  fi
  
  # Try to parse the release tag name using jq if available, otherwise fall back to grep/cut
  if command -v jq &> /dev/null; then
    RELEASE_TAG=$(echo "$RELEASE_INFO" | jq -r '.tag_name')
    echo -e "${BLUE}Using jq for JSON parsing${NC}"
  else
    echo -e "${YELLOW}jq not found, falling back to basic parsing${NC}"
    RELEASE_TAG=$(echo "$RELEASE_INFO" | grep -o '"tag_name": "[^"]*' | head -1 | cut -d'"' -f4)
  fi
  
  if [ -z "$RELEASE_TAG" ] || [ "$RELEASE_TAG" = "null" ]; then
    # If release tag couldn't be determined, try to use v1.0.0 as a fallback
    echo -e "${YELLOW}Warning: Could not determine latest release tag.${NC}"
    echo -e "${YELLOW}Trying fallback to v1.0.0...${NC}"
    RELEASE_TAG="v1.0.0"
  fi
  
  echo -e "${GREEN}Selected release: $RELEASE_TAG${NC}"
}

# Download the appropriate binary
download_binary() {
  local filename="$BINARY_NAME"_"$OS"_"$ARCH".tar.gz
  local download_url="$GITHUB_REPO/releases/download/$RELEASE_TAG/$filename"
  local checksums_url="$GITHUB_REPO/releases/download/$RELEASE_TAG/checksums.txt"
  
  echo -e "${BLUE}Downloading $filename...${NC}"
  
  cd "$TEMP_DIR"
  
  if command -v curl &> /dev/null; then
    curl -L -o "$filename" "$download_url"
    curl -L -o "checksums.txt" "$checksums_url"
  elif command -v wget &> /dev/null; then
    wget -q "$download_url" -O "$filename"
    wget -q "$checksums_url" -O "checksums.txt"
  else
    echo -e "${RED}Error: curl or wget is required but not installed.${NC}"
    exit 1
  fi
  
  # Verify checksum
  echo -e "${BLUE}Verifying checksum...${NC}"
  if command -v sha256sum &> /dev/null; then
    local expected_checksum=$(grep "$filename" checksums.txt | awk '{print $1}')
    
    # Check if the checksum entry exists
    if [ -z "$expected_checksum" ]; then
      echo -e "${RED}Checksum entry not found for $filename.${NC}"
      exit 1
    fi
    
    local actual_checksum=$(sha256sum "$filename" | awk '{print $1}')
    
    if [ "$expected_checksum" != "$actual_checksum" ]; then
      echo -e "${RED}Checksum verification failed. Please try again.${NC}"
      exit 1
    fi
  else
    echo -e "${YELLOW}Warning: sha256sum not found. Skipping checksum verification.${NC}"
  fi
  
  echo -e "${GREEN}Download complete.${NC}"
  
  # Extract the archive
  echo -e "${BLUE}Extracting archive...${NC}"
  tar xzf "$filename"
  
  # Find the binary in the extracted content - using more compatible approach
  local extracted_binary=""
  
  # First look for an exact match with the binary name
  if [ -f "$BINARY_NAME" ]; then
    extracted_binary="$BINARY_NAME"
  # Then check if it exists with OS and ARCH suffix
  elif [ -f "${BINARY_NAME}_${OS}_${ARCH}" ]; then
    extracted_binary="${BINARY_NAME}_${OS}_${ARCH}"
  else
    # Fall back to a more generic search using find without -executable flag
    if [ "$OS" = "windows" ]; then
      # For Windows, look for .exe files
      extracted_binary=$(find . -type f -name "${BINARY_NAME}*.exe" | head -1)
    else
      # For Unix-like systems, just look for the binary name
      extracted_binary=$(find . -type f -name "${BINARY_NAME}*" | grep -v ".tar.gz" | head -1)
    fi
  fi
  
  if [ -z "$extracted_binary" ]; then
    echo -e "${RED}Error: Could not locate the binary in the archive.${NC}"
    echo -e "${YELLOW}Contents of extracted archive:${NC}"
    ls -la
    exit 1
  fi
  
  echo -e "${GREEN}Found binary: $extracted_binary${NC}"
  
  # Make sure it's executable
  chmod +x "$extracted_binary"
  
  # Move to a standard name for installation
  mv "$extracted_binary" "$BINARY_NAME"
  
  if [ "$OS" = "windows" ]; then
    mv "$BINARY_NAME" "${BINARY_NAME}.exe"
    BINARY_NAME="${BINARY_NAME}.exe"
  fi
}

# Install the binary
install_binary() {
  echo -e "${BLUE}Installing to $(get_install_dir)...${NC}"
  
  local install_dir=$(get_install_dir)
  
  # Create install directory if it doesn't exist
  mkdir -p "$install_dir"
  
  # Check write permissions
  if [ ! -w "$install_dir" ]; then
    echo -e "${YELLOW}Elevated permissions required. Using sudo...${NC}"
    sudo mv "$TEMP_DIR/$BINARY_NAME" "$install_dir/"
    sudo chmod +x "$install_dir/$BINARY_NAME"
  else
    mv "$TEMP_DIR/$BINARY_NAME" "$install_dir/"
    chmod +x "$install_dir/$BINARY_NAME"
  fi
  
  echo -e "${GREEN}Figurine installed successfully to $install_dir/$BINARY_NAME${NC}"
}

# Get appropriate install directory
get_install_dir() {
  if [ "$OS" = "windows" ]; then
    echo "$WINDOWS_INSTALL_DIR"
  else
    echo "$INSTALL_DIR"
  fi
}

# Configure shell
configure_shell() {
  if [ "$OS" = "windows" ]; then
    echo -e "${YELLOW}Windows detected. Please add $WINDOWS_INSTALL_DIR to your PATH manually.${NC}"
    return
  fi
  
  echo -e "${BLUE}Checking if figurine is in PATH...${NC}"
  
  local install_dir=$(get_install_dir)
  
  if echo "$PATH" | grep -q "$install_dir"; then
    echo -e "${GREEN}$install_dir is already in PATH.${NC}"
    return
  fi
  
  echo -e "${YELLOW}Would you like to add figurine to your shell configuration? [Y/n]${NC}"
  read -r response
  
  case "$response" in
    [nN][oO]|[nN])
      echo -e "${BLUE}Skipping shell configuration.${NC}"
      return
      ;;
  esac
  
  local shell_config=""
  
  if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      shell_config="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      shell_config="$HOME/.bash_profile"
    fi
    echo -e "${BLUE}Adding to Bash configuration...${NC}"
  elif [ -n "$ZSH_VERSION" ]; then
    shell_config="$HOME/.zshrc"
    echo -e "${BLUE}Adding to Zsh configuration...${NC}"
  elif [ -f "$HOME/.config/fish/config.fish" ]; then
    shell_config="$HOME/.config/fish/config.fish"
    echo -e "${BLUE}Adding to Fish configuration...${NC}"
  else
    echo -e "${YELLOW}Could not determine shell configuration file. Please add $install_dir to your PATH manually.${NC}"
    return
  fi
  
  if [ -n "$shell_config" ]; then
    local config_line=""
    
    if [ -f "$HOME/.config/fish/config.fish" ]; then
      config_line="fish_add_path $install_dir"
    else
      config_line="export PATH=\"\$PATH:$install_dir\""
    fi
    
    echo -e "\n# Added by figurine installer\n$config_line" >> "$shell_config"
    echo -e "${GREEN}Added $install_dir to PATH in $shell_config${NC}"
    echo -e "${YELLOW}Please restart your shell or run 'source $shell_config' to update your PATH.${NC}"
  fi
  
  # Add shell function to show hostname using figurine
  echo -e "${YELLOW}Would you like to add a greeting with figurine when opening a new terminal? [Y/n]${NC}"
  read -r greeting_response
  
  case "$greeting_response" in
    [nN][oO]|[nN])
      echo -e "${BLUE}Skipping greeting configuration.${NC}"
      return
      ;;
  esac
  
  if [ -n "$shell_config" ]; then
    local greeting_cmd=""
    
    if [ -f "$HOME/.config/fish/config.fish" ]; then
      greeting_cmd='echo ""; '$install_dir'/'$BINARY_NAME' -f "3d.flf" (hostname); echo ""'
    else
      greeting_cmd='echo ""; '$install_dir'/'$BINARY_NAME' -f "3d.flf" $(hostname); echo ""'
    fi
    
    echo -e "\n# Figurine greeting\n$greeting_cmd" >> "$shell_config"
    echo -e "${GREEN}Added figurine greeting to $shell_config${NC}"
  fi
}

# Display a demo of the installed binary
show_demo() {
  local install_dir=$(get_install_dir)
  
  echo -e "${BLUE}\nDemonstration:${NC}"
  "$install_dir/$BINARY_NAME" -f "3d.flf" "Figurine"
  echo ""
}

# Main installation flow
main() {
  print_banner
  detect_platform
  get_repo_info  # Initialize repository information before fetching releases
  get_latest_release
  download_binary
  install_binary
  configure_shell
  show_demo
  echo -e "${GREEN}Installation complete!${NC}"
}

# Parse arguments and run the main function
parse_args "$@"
main