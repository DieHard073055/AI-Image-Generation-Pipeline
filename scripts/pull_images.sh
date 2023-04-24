# Check if required variables are set
required_variables=("singapore_home_user" "singapore_home_ip" "singapore_home_port")

for var_name in "${required_variables[@]}"; do
    if [ -z "${!var_name}" ]; then
        echo "Error: Missing required variable '$var_name'. Please set it before running the script."
        exit 1
    fi
done


# Set up the SSH parameters for the remote machine
singapore_ssh_params="${singapore_home_user}@${singapore_home_ip}"

# List the image files in the ~/tmp/generated_pics/ directory on the remote machine and save the output to a local file called images_to_pull
ssh -p ${singapore_home_port} ${singapore_ssh_params} "ls ~/tmp/generated_pics/*.png" > images_to_pull

# Download each image to the local machine using rsync
for image in $(cat images_to_pull)
do
  rsync -avz -e "ssh -p ${singapore_home_port}" ${singapore_ssh_params}:${image} ./
done

# Remove all image files in the ~/tmp/generated_pics/ directory on the remote machine
ssh -p ${singapore_home_port} ${singapore_ssh_params} "rm -rf ~/tmp/generated_pics/*.png"
