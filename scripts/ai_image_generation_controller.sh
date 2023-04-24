# Check if required variables are set
required_variables=("password" "docker_container_id" "singapore_home_user" "singapore_home_ip" "singapore_home_port")

for var_name in "${required_variables[@]}"; do
    if [ -z "${!var_name}" ]; then
        echo "Error: Missing required variable '$var_name'. Please set it before running the script."
        exit 1
    fi
done

# Set up variables and file paths
wk_dir="Documents\\code\\AI"
go_to_wk_dir="powershell; cd $wk_dir"

negative_prompt_input=$(cat negative_input)
num_of_images_per_prompt=20
image_width=512
image_height=768

web_request_template="Invoke-WebRequest -Uri http://localhost:5000/predictions -Method Post -Headers @{ \"Content-Type\" = \"application/json\" } -Body "

invoke_script_contents="\$postParams = '{\"input\": {\"prompt\": \""
invoke_script_content_negative="\",\"negative_prompt\": \""
invoke_script_content_end="\",\"sampler_name\": \"DPM++ SDE Karras\",\"steps\": \"20\",\"cfg_scale\": \"8\",\"width\": \"${image_width}\",\"height\": \"${image_height}\",\"seed\": \"'+\$args[0]+'\"  }}'"

# Read prompts from the batch_requests file
while IFS=$'\n' read prompt; do
    [ -z "$prompt" ] && continue

    # Generate a PowerShell script (invoke.ps1) for each prompt
    echo "${invoke_script_contents} ${prompt} ${invoke_script_content_negative} ${negative_prompt_input} ${invoke_script_content_end}" > invoke.ps1
    echo "\$response = ${web_request_template} \$postParams -UseBasicParsing" >> invoke.ps1
    echo "Write-Output done" >> invoke.ps1

    # Copy the invoke.ps1 script to the remote machine (pc)
    sshpass -p $password scp ./invoke.ps1 pc:$wk_dir < /dev/null

    # Run the invoke.ps1 script on the remote machine
    sshpass -p $password ssh pc "$go_to_wk_dir; ./run_invoke.ps1 $num_of_images_per_prompt" < /dev/null

    # Transfer the generated images to another remote machine (singapore_home_user at singapore_home_ip)
    sshpass -p $password ssh pc "docker exec ${docker_container_id} /bin/sh -c \"mv *.png tmp; scp -v -P8022 -r tmp/*.png ${singapore_home_user}@${singapore_home_ip}:~/tmp/generated_pics/; rm tmp/*.png\"" < /dev/null

done < batch_requests
