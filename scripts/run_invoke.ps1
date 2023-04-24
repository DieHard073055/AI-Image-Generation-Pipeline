# Executes the invoke.ps1 script for a specified number of iterations
$num_iterations = $args[0]
echo "Will be executing $num_iterations times"
for (($i = 0); $i -lt $num_iterations; $i++){
    # The argument to invoke.ps1 is the seed
    .\invoke.ps1 $i
}
