#!/bin/bash

# Check if the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with root privileges. Please use sudo or run as root."
    exit 1
fi

# Check the system architecture
architecture=$(uname -m)
if [ "$architecture" != "x86_64" ] && [ "$architecture" != "aarch64" ]; then
    echo "This script is intended for x86_64 or aarch64 (arm64) architectures only. Aborting."
    exit 1
fi

force=false

# Check for the -f flag
while getopts ":f" opt; do
    case ${opt} in
        f )
            force=true
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Specify GitHub repository owner and repository name
repo_owner="arsham"
repo_name="figurine"

# Check if figurine already exists in /usr/local/bin
if ! $force && command -v figurine &> /dev/null; then
    echo "Figurine binary already exists in /usr/local/bin. Use -f flag to force download and installation."
    exit 1
fi

# Determine the appropriate file suffix based on the system architecture
if [ "$architecture" == "x86_64" ]; then
    file_suffix="figurine_linux_amd64.*"
elif [ "$architecture" == "aarch64" ]; then
    file_suffix="figurine_linux_arm64.*"
fi

# Create a temporary directory
temp_dir=$(mktemp -d)

# Download the latest release asset to the temporary directory
curl -s "https://api.github.com/repos/${repo_owner}/${repo_name}/releases/latest" \
| grep "$file_suffix" \
| cut -d : -f 2,3 \
| tr -d \" \
| wget -qi - -P "$temp_dir"

# Extract the downloaded file
ls ${temp_dir}
if [ -e "${temp_dir}/figurine"* ]; then
    tar -xzf "${temp_dir}/figurine"* -C "$temp_dir"
else
    echo "Failed to extract the downloaded file. Exiting."
    rm -r "$temp_dir"
    exit 1
fi

# Move the binary to /usr/local/bin
mv "${temp_dir}/deploy/figurine" "/usr/local/bin/"

# Clean up temporary directory
rm -r "$temp_dir"

echo "Latest release downloaded and installed to /usr/local/bin successfully."

# Prompt user for the name
read -p "Enter a name: " name

# Specify the content for figurine.sh
figurine_script_content="#!/bin/bash

echo ''
/usr/local/bin/figurine -f '3d.flf' $name
"

# Write the content to figurine.sh in /etc/profile.d (force overwrite)
echo "$figurine_script_content" | sudo tee /etc/profile.d/figurine.sh >/dev/null

echo "Figurine script created successfully in /etc/profile.d/figurine.sh."
