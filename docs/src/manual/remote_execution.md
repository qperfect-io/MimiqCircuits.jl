# Execution on MIMIQ

This page provides detailed information on how to execute quantum circuits on MIMIQ's remote services.
Use the following links to navigate through the sections:

- [Execution on MIMIQ](#execution-on-mimiq)
  - [Cloud Service](#cloud-service)
    - [Overview](#overview)
    - [Job Management](#job-management)
    - [Terms of Service](#terms-of-service)
    - [User Management](#user-management)
  - [Connecting to server for sending jobs](#connecting-to-server-for-sending-jobs)
    - [Credentials](#credentials)
    - [Tokens](#tokens)
  - [Execution](#execution)
  - [Results](#results)
    - [Getting results (Cloud server)](#getting-results-cloud-server)
    - [Getting results (Julia session)](#getting-results-julia-session)
    - [Format of Results](#format-of-results)
    - [Plotting results](#plotting-results)
    - [Saving and loading results](#saving-and-loading-results)
  - [Useful Job Management Features](#useful-job-management-features)
    - [Check job status](#check-job-status)
    - [List all jobs](#list-all-jobs)
    - [Get inputs](#get-inputs)

## Cloud Service

MIMIQ provides remote execution of quantum circuits via its cloud services, allowing users to run quantum jobs on high-performance infrastructure. You can connect to the cloud server by providing your credentials and accessing the MIMIQ cloud URL at [https://mimiq.qperfect.io/sign-in].

### Overview

The MIMIQ Cloud Service offers multiple features for managing job executions, user roles, and organizational access. Below is a screenshot of the **Cloud Dashboard** that you will find in the server website.

![Cloud Dashboard](../assets/cloud_dashboard.png)

### Job Management

The Job Management or Executions section provides a comprehensive view of all quantum jobs submitted. Users can track the status of their jobs, cancel jobs, retrieve results and view detailed information, including start time, completion time, and current status. For **Organization Managers**, additional features are available:

- View Other Users' Jobs: Organization managers can view jobs submitted by all users in their organization, allowing them to monitor the workload.
- Cancel Jobs: Managers also have the ability to cancel any job within their organization if necessary, providing greater control over resource management.
  
This section is essential for both tracking the progress of jobs and managing computational resources effectively.

**Job status**

The Status tab allows you to filter jobs based on their status. By clicking on the tab, you can select a specific status (e.g., NEW), and then click on the Search button to view all jobs that match the selected status.

When a job is submitted to the MIMIQ cloud services, it goes through various status stages:

- `NEW`: When a job is initially submitted, its status is marked as NEW, indicating that it has entered the queue but has not started executing yet. In this stage, the job is waiting for previous jobs in the queue to complete, whether they finish successfully or encounter errors.

- `RUNNING`: Once all prior jobs are completed, your job will begin execution, and its status will change to RUNNING. At this point, the job is actively being processed by the MIMIQ engine, either by the statevector simulator or MPS algorithm, depending on the job configuration.

- `DONE`: Upon successful completion, the job status changes to DONE, indicating that the quantum circuit has finished executing and the results are available for retrieval.

- `ERROR`: If the job encounters an issue during execution, such as exceeding the time limit or encountering hardware or software errors, its status will change to ERROR. Users can then review the error logs to diagnose the problem. You can also hover your mouse over the word `ERROR` and a short error message will appear.

**Job ID**

The ID tab shows a unique identifier for each job. This identifier can be used to retrieve results using [`getresults`](@ref), see [results](#results) section.

### Terms of Service

When an Organization Manager first connects to the server they need to accept the `Terms of Service` in order to activate the cloud subscription. The organization users will then be able to send jobs. The Terms of Service is also available for the users to read it.

### User Management

The User Management section is available exclusively to users with the Organization Manager role.

Key features of user management include:

- Adding New Users: Organization managers can invite new users to join their organization, enabling them to submit jobs. However, there is a limit to how many users can be added based on the organization’s plan.
- Role Management: Organization managers can assign roles and manage permissions within their team, ensuring that the right users have the necessary access to cloud resources.

## Connecting to server for sending jobs

In order to execute a circuit in the remote, you first need to connect to it, see also [quickstart](../quick_start.md) page.

### Credentials

You can connect to the MIMIQ server using the [`connect`](@ref) function and providing your credentials (username and password). If you do not supply your credentials directly in the function call, you will be redirected to a localhost page where you can securely enter your credentials. This method is preferred for better security, as it avoids storing your username and password in the script.

```julia
# Connect to the server (opens a browser for login)
conn = connect()

# Connect using Credentials directly
conn = connect("your_username", "your_password")
```

### Tokens

Instead of using your credentials every time you connect to the MIMIQ services, you can authenticate once and save a token. This token can be saved to a JSON file and reused across different sessions, making it a secure and efficient way to manage authentication.

**How Token Authentication Works**:

- First Authentication: You log in once using your credentials (via browser or directly), and the token is generated.
- Saving the Token: You can save this token in a JSON file using the savetoken method.
- Loading the Token: Later, you can load the saved token with the loadtoken method to reconnect without providing your credentials again.
This is a safer method, as it avoids hardcoding sensitive information like passwords in your scripts.

After authentication, this is how it looks:

```julia
# Save the token to a file (example_token.json)
savetoken("example_token.json")

# Load the token from a saved file to reconnect
conn = loadtoken("example_token.json")
```

You can also accomplish all at once (connecting through a token if possible, otherwise connecting via the browser and then saving the token) using this code block:

```julia
conn = try
    loadtoken()
catch
    savetoken()
    loadtoken()
end
```

!!! Note
      Tokens stay valid only for one day.

## Execution

MIMIQ supports sending quantum circuits to its remote services for execution either as a **single circuit** or in **batch mode**, i.e. multiple circuits at once. In both cases, circuits are initialized in the zero state, and results are obtained by running the circuit and sampling.

You can submit one or multiple circuits for execution using the [`execute`](@ref) function, which can be called as `execute(connection, circuits; kwargs...)`. This unified interface simplifies quantum job management, whether you're running a single job or a batch of jobs.

**Parameters**:

- **connection**: The connection object used to communicate with the MIMIQ remote services.
- **circuit(s)**: A single quantum circuit or a list of circuits. These can be provided as MIMIQ [`Circuit`](@ref) objects or paths to valid `.pb`, `.qasm` or `.stim` files. See [Import and Export](import_export.md) and [circuits](circuits.md) pages.

- **kwargs...**: Additional options to customize execution:
  - **label**: A descriptive name for the simulation or batch.
  - **algorithm**: The backend method to perform the simulation: `"auto"`, `"statevector"`, or `"mps"`. The default is `"auto"`, which automatically selects between the statevector or MPS algorithm, depending on the circuit sent. See [simulation](simulation.md) page for more information.
  - **nsamples**: Number of measurement samples to generate (default: 1000, maximum: 65536). See [simulation](simulation.md) for details on sampling.
  - **bitstrings**: A list of bitstrings to compute amplitudes for. This is equivalent to adding an [`Amplitude`](@ref) operation at the end of the circuit, see [amplitudes](statistical_ops.md#amplitude) section. The results will be stored at the end of the Z-register.
  - **timelimit**: Maximum execution time in minutes (default: 30).
  - **bonddim**: Bond dimension for MPS (default: 256). See [simulation](simulation.md) page.
  - **entdim**: Entangling dimension for MPS (default: 16). See [simulation](simulation.md) page.
  - **seed**: Seed for random number generator.

**Return type: Jobs**:

It is important to note that the [`execute`](@ref) function returns an object of type [`Execution`](@ref). This object can then be passed to other functions to get results or status updates (see [results](#results) and [job management](#job-management) sections). However, if for some reason we lose access to this object, or we simply want to connect to the same job in a different session, we can do so like this:

```julia
job = Execution("job-id")
```

Here, `"job-id"` is the unique identifier of the job, which you can find in the dashboard of the web interface, see [cloud service](#cloud-service) section.

**Example**:

```@example Execute
using MimiqCircuits # hide
str_name = get(ENV, "MIMIQCLOUD", nothing) # hide
new_url = # hide
    str_name == "QPERFECT_CLOUD" ? QPERFECT_CLOUD : # hide
    str_name == "QPERFECT_DEV" ? QPERFECT_DEV : # hide
    isnothing(str_name) ? QPERFECT_CLOUD : # hide
    str_name # hide
conn = connect(ENV["MIMIQUSER"], ENV["MIMIQPASS"]; url=new_url) # hide
# Prepare multiple circuits and execute them in batch mode # hide

# Prepare circuits
c1 = Circuit()
c2 = Circuit()

# Add gates to the circuits
push!(c1, GateX(), 1)
push!(c2, GateH(), 2)

# Execute Single circuit
job_single = execute(conn, c1; nsamples=1000, label="Single_run")

# Execute circuits in batch mode
job_batch = execute(conn, [c1, c2]; nsamples=1000, label="batch_run")
```

## Results

After submitting executions, you can retrieve your simulation results in two different ways: through the cloud server, or from your Julia session.

!!! warning
    The job results will be deleted from the remote server after some time, so make sure to retrieve them in time. Contact your organization manager to understand how long results will be stored in the server. Note also that results will be deleted after a shorter period of time once the user has downloaded them at least once.

### Getting results (Cloud server)

You can download results directly from the cloud server web interface by clicking the box under the *Resulted files* tab, see [cloud server](#cloud-service) section. This will download a Protobuf file (`.pb`) and save it locally. The results can then be loaded to your Julia session using the [`loadproto`](@ref) function.

To learn more about Protobuf and how to save/load results, check out the [import & export](import_export.md) page, and the [saving and loading results](#saving-and-loading-results) section.

### Getting results (Julia session)

You can download results from your Julia session using two functions: [`getresult`](@ref) and [`getresults`](@ref).

The only difference between the two is that `getresults` retrieves the results of *all* the circuits sent in a job, whereas `getresult` only returns the result of the first circuit making it a more lightweight version. This is useful if you want to peek at the results before all circuits of a given job have finished. (If only one circuit was sent then there's no difference.)

They are both called in a similar way as `getresults(connection, execution; kwargs...)`.

**Parameters:**

- `connection (Connection)`: The active connection to the MIMIQ services, see [connection](#connecting-to-server-for-sending-jobs) section.
- `execution (Execution)`: The execution object representing the job whose results are to be fetched, see [execution](#execution) section. If you saved the output of `execute` then you can pass it to `getresults` (see example below). If you didn't save it, then you can copy the job ID from the Cloud server (see [cloud service](#cloud-service) section) and pass it to `getresults` as `Execution("job-id")`.
- `interval (Int)`: Time interval in seconds between calls to the remote to check for job completion (default: 1 second). A shorter interval results in more frequent checks, while a longer interval reduces the frequency of status checks, saving computational resources.

!!! warning
    Both `getresults` and `getresult` block further code execution until the job requested has finished. If you want to check the status of the job before attempting to retrieve results, we recommend using [`isjobdone`](@ref), see [job management](#useful-job-management-features) section.

!!! note
    `getresult` internally calls `getresults` but only returns the first result if multiple results are retrieved.

**Example:**

```@example Execute
using MimiqCircuits # hide
str_name = get(ENV, "MIMIQCLOUD", nothing) # hide
new_url = # hide
    str_name == "QPERFECT_CLOUD" ? QPERFECT_CLOUD : # hide
    str_name == "QPERFECT_DEV" ? QPERFECT_DEV : # hide
    isnothing(str_name) ? QPERFECT_CLOUD : # hide
    str_name # hide
conn = connect(ENV["MIMIQUSER"], ENV["MIMIQPASS"]; url=new_url) # hide
# Prepare multiple circuits and execute them in batch mode # hide

# Prepare circuits # hide
c1 = Circuit() # hide
c2 = Circuit() # hide

# Add gates to the circuits # hide
push!(c1, GateX(), 1) # hide
push!(c2, GateH(), 2) # hide

# Execute Single circuit # hide
job_single = execute(conn, c1; nsamples=1000, label="Single_run") # hide

# Execute circuits in batch mode # hide
job_batch = execute(conn, [c1, c2]; nsamples=1000, label="batch_run") # hide

# Getting the Results
res_single = getresult(conn, job_single)
res_batch = getresults(conn, job_batch)
```

### Format of Results

When you retrieve jobs results, you will get back a [`QCSResults`](@ref) object (when using `getresult`) or a `Vector{QCSResults}` (when using `getresults`). Each `QCSResults` object contains information about job executed. You can get an overview by printing it:

```plaintext
QCSResults:
├── simulator: MIMIQ-StateVector 0.14.1
├── timings:
│    ├── total time: 0.00036376400000000004s
│    ├── compression time: 4.792e-06s
│    ├── apply time: 2.2727e-05s
│    └── parse time: 8.9539e-05s
├── fidelity estimate: 1
├── average multi-qubit gate error estimate: 0
├── creg (most sampled):
│    ├── bs"0011" => 136
│    ├── bs"0101" => 135
│    ├── bs"0111" => 134
│    ├── bs"0010" => 129
│    └── bs"0100" => 117
├── 1 executions
├── 0 amplitudes
└── 1000 samples
```

The [`QCSResults`](@ref) object has different fields that you can access:

**Key fields:**

- **simulator** (`String`): Name of the simulator used, e.g., `MIMIQ-StateVector`.
- **version** (`String`): Version of the simulator used, e.g. `0.14.1`.
- **fidelities** (`Vector{Float64}`): Fidelity estimates for each of the circuits executed (between 0 and 1).
- **avggateerrors** (`Vector{Float64}`): Average multiqubit gate errors. This value represents the average fidelity that multi-qubit gates would need to have in a real quantum computer in order to yield the same fidelity as the MIMIQ simulation.
- **cstates** (`Vector{BitString}`): Vector with the sampled values of the classical registers, i.e. of measurements. See [circuit](circuits.md) and [non-unitary operations](non_unitary_ops.md) pages.
- **zstates** (`Vector{ComplexF64}`): Vector with the values of the Z-registers, i.e. of expectation values, entanglement measures, etc. See [circuit](circuits.md) and [statistical operations](statistical_ops.md) pages.
- **amplitudes** (`Dict{BitString, ComplexF64}`): Number of amplitudes retrieved.
- **timings** (`Dict{String, Float64}`): Time taken for different stages of the execution. You can access:
  - **"total"** (`Float64`): The entire time elapsed during execution.
  - **"parse"** (`Float64`): Time taken to parse the circuit.
  - **"compression"** (`Float64`): Time to convert the circuit to an efficient execution format.
  - **"apply"** (`Float64`): Time to apply all operations. It also includes the time to allocate the initial state.

!!! note
    To understand how MIMIQ samples measurements into the classical register, check the [simulation](simulation.md) page.

Here's an example of how to access different fields:

```@example Execute
using MimiqCircuits # hide
str_name = get(ENV, "MIMIQCLOUD", nothing) # hide
new_url = # hide
    str_name == "QPERFECT_CLOUD" ? QPERFECT_CLOUD : # hide
    str_name == "QPERFECT_DEV" ? QPERFECT_DEV : # hide
    isnothing(str_name) ? QPERFECT_CLOUD : # hide
    str_name # hide
conn = connect(ENV["MIMIQUSER"], ENV["MIMIQPASS"]; url=new_url) # hide
# Prepare multiple circuits and execute them in batch mode # hide

# Prepare circuits # hide
ghz = Circuit() # hide

# Add gates to the circuits # hide
push!(ghz, GateH(), 1) # hide
push!(ghz, GateCX(), 1, 2:10) # hide

# Execute Single circuit # hide
job_single = execute(conn, ghz; nsamples=1000, label="Single_run") # hide

# Getting the Results # hide
res_single = getresult(conn, job_single) # hide

# Get fidelity
fids = res_single.fidelities
println(fids)

# Get total execution time
tot = res_single.timings["total"]
println(tot)

# Get classical registers of the first 10 samples
first_samples = res_single.cstates[1:10]
println(first_samples)
```

With the output of [`getresults`](@ref) it works the same way, except you have to access one of the circuit results, i.e. `res_batch[index]` instead of `res_single`.

### Plotting results

You can visualize the results of your circuit execution using the `Plots` package. The example below shows how to plot the results from executing a single circuit.

**Example**:

```@example Execute
using MimiqCircuits # hide
str_name = get(ENV, "MIMIQCLOUD", nothing) # hide
new_url = # hide
    str_name == "QPERFECT_CLOUD" ? QPERFECT_CLOUD : # hide
    str_name == "QPERFECT_DEV" ? QPERFECT_DEV : # hide
    isnothing(str_name) ? QPERFECT_CLOUD : # hide
    str_name # hide
conn = connect(ENV["MIMIQUSER"], ENV["MIMIQPASS"]; url=new_url) # hide
# Prepare multiple circuits and execute them in batch mode # hide

# Prepare circuits # hide
c1 = Circuit() # hide

# Add gates to the circuits # hide
push!(c1, GateH(), 1) # hide
push!(c1, GateCX(), 1, 2:10) # hide

# Execute Single circuit # hide
job_single = execute(conn, c1; nsamples=1000, label="Single_run") # hide

# Getting the Results # hide
res_single = getresult(conn, job_single) # hide

using Plots
plot(res_single)
```

### Saving and loading results

After retrieval, if you want to save the results locally, you can save them as a Protobuf file (`.pb`) using the [`saveproto`](@ref) function. You can load back the results using [`loadproto`](@ref). This format ensures minimal file size while maintaining all the necessary data.

To learn more about Protobuf and how to save/load results, check out the [import & export](import_export.md) page.

!!! note
    Results from batch simulations need to be saved one by one.

Here is an example:

```@example Execute
using MimiqCircuits # hide
str_name = get(ENV, "MIMIQCLOUD", nothing) # hide
new_url = # hide
    str_name == "QPERFECT_CLOUD" ? QPERFECT_CLOUD : # hide
    str_name == "QPERFECT_DEV" ? QPERFECT_DEV : # hide
    isnothing(str_name) ? QPERFECT_CLOUD : # hide
    str_name # hide
conn = connect(ENV["MIMIQUSER"], ENV["MIMIQPASS"]; url=new_url) # hide
# Prepare multiple circuits and execute them in batch mode # hide

# Prepare circuits # hide
c1 = Circuit() # hide
c2 = Circuit() # hide

# Add gates to the circuits # hide
push!(c1, GateX(), 1) # hide
push!(c2, GateH(), 2) # hide

# Execute Single circuit # hide
job_single = execute(conn, c1; nsamples=1000, label="Single_run") # hide

# Execute circuits in batch mode # hide
job_batch = execute(conn, [c1, c2]; nsamples=1000, label="batch_run") # hide

# Getting the Results # hide
res_single = getresult(conn, job_single) # hide
res_batch = getresults(conn, job_batch) # hide

# Saving Single Result
saveproto("res_single.pb", res_single)

# Saving Batch Result (Should be saved one by one)
saveproto("res_batch_1.pb", res_batch[1])

# Loading Results
loadproto("res_single.pb", QCSResults)
loadproto("res_batch_1.pb", QCSResults)
```

## Useful Job Management Features

MIMIQ provides several functions to facilitate job management. For this you need to have a connection established, and possibly a job id or object (see [connection](#connecting-to-server-for-sending-jobs) and [execution](#execution) sections).

### Check job status

You can check the status of jobs using [`isjobdone`](@ref), [`isjobfailed`](@ref), [`isjobcanceled`](@ref), [`isjobstarted`](@ref). These functions check whether the job's status is `DONE`, `ERROR`, `CANCELED` or `RUNNING`, respectively, and return a boolean.

You can find this information also in the cloud server, but doing it from within the Julia session allows you to perform different actions depending on job status. It is particularly useful to avoid a call to `getresults` to take too long because a job has not finished yet (check [results](#results) section).

To call them, we simply do:

```julia
isjobdone(connection, job)
isjobfailed(connection, job)
isjobcanceled(connection, job)
isjobstarted(connection, job)
```

### List all jobs

You can get a list of all job requests sent to MIMIQ's cloud server using [`requests`](@ref). This can be useful for monitoring job history and active requests.

This function accepts several options, which you can use to filter by `status` (i.e. `"NEW"`, `"RUNNING"`, `"ERROR"`, `"CANCELED"`, `"DONE"`) or by `userEmail`. You can also change the limit for the amount of requests retrieved using `limit`.

Here's an example to get the last 100 new jobs:

```julia
requests(connection, status = "NEW", limit = 100)
```

### Get inputs

You can retrieve the input circuits and parameter files for every job using [`getinput`](@ref) or [`getinputs`](@ref). The former fetches the data of the first circuit in the job, whereas the latter retrieves all inputs from all circuits in the job (useful in batch mode). This is similar to `getresult` vs `getresults`.

```julia
  circuits, parameters = getinputs(connection, job)
```
