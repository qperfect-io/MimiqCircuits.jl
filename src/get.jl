#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

"""
    getinputs(connection, execution)

Returns the circuit and parameters for the given execution.
"""
function getinputs(conn::Connection, ex::Execution)
    tmpdir = mktempdir(; prefix="mimiq_in_")
    names = MimiqLink.downloadjobfiles(conn, ex, tmpdir)

    if "parameters.json" ∉ basename.(names)
        error("$ex is not a valid execution for MimiqCircuits: missing files")
    end

    parameters = JSON.parsefile(joinpath(tmpdir, "parameters.json"))

    if CIRCUITPB_FILE in basename.(names)
        circuit = loadproto(joinpath(tmpdir, CIRCUITPB_FILE), Circuit)
    elseif CIRCUITQASM_FILE in basename.(names)
        circuit = joinpath(tmpdir, CIRCUITQASM_FILE)
        @info "Downloaded QASM input as $circuit"
    else
        error("No valid circuit file found. Input parameters not valid.")
    end

    return circuit, parameters
end

"""
    getresults(connection, execution; kwargs...)

Block until the given execution is finished and return the results.

##  Keyword Arguments

* `interval`: time interval in seconds to check for job completion (default: 1)
"""
function getresults(conn::Connection, ex::Execution; interval=1)
    # wait for the job to finish
    while !isjobdone(conn, ex)
        sleep(interval)
    end

    infos = MimiqLink.requestinfo(conn, ex)

    if infos["status"] == "ERROR"
        if haskey(infos, "errorMessage")
            msg = infos["errorMessage"]
            error("Remote job errored: $msg")
        else
            error("Remote job errored. If the error persists, please contact support.")
        end
    elseif infos["status"] == "CANCELED"
        error("Remote job canceled.")
    end

    tmpdir = mktempdir(; prefix="mimiq_res_")

    names = MimiqLink.downloadresults(conn, ex, tmpdir)

    if RESULTSPB_FILE ∉ basename.(names)
        error("$ex is not a valid execution for MimiqCircuits: missing files")
    end

    res = loadproto(joinpath(tmpdir, RESULTSPB_FILE), QCSResults)

    return res
end
