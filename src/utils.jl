#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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

function _pkgversion(mod)
    if VERSION < v"1.9"
        return Pkg.TOML.parsefile(joinpath(pkgdir(mod), "Project.toml"))["version"]
    end
    return pkgversion(mod)
end

# checks if a file is a valid qasm 2 file
function _check_file_qasm2(f::AbstractString)
    open(f, "r") do io
        while true

            line = readline(io)

            # if line starts with // or if the line has only spaces
            if startswith(line, "//") || isempty(line) || all(isspace, line)
                continue
            end

            if !startswith(line, "OPENQASM 2.0;")
                throw(ArgumentError("File is not a valid QASM 2.0 file"))
            end

            # if startswith(line, "OPENQASM 2.0;")
            break
        end
    end
end

function _setmpsdims!(pars, algorithm, bonddim, entdim; force=false)
    if algorithm != "auto" && algorithm != "mps"
        return pars
    end

    if isnothing(bonddim)
        pars["bondDimension"] = DEFAULT_BONDDIM
    else
        if bonddim < MIN_BONDDIM || bonddim > MAX_BONDDIM
            throw(ArgumentError(("Bond dimension should be ∈[1,4096]")))
        end
        pars["bondDimension"] = bonddim
    end

    if isnothing(entdim)
        pars["entDimension"] = DEFAULT_ENTDIM
    else
        if entdim < MIN_ENTDIM
            if !force
                throw(ArgumentError("Entangling dimension should be ∈[4,64]"))
            else
                @warn "Running simulation with entdim=$(entdim). Results may be misleading."
            end
        elseif entdim > MAX_ENTDIM
            throw(ArgumentError("Entangling dimension should be ∈[4,64]"))
        end
        pars["entDimension"] = entdim
    end

    return pars
end

function _setextraargs!(pars, kwargs...)
    for (key, val) in kwargs
        pars[string(key)] = val
    end

    return pars
end

function _gettimelimit(conn::Connection)
    limits = fetch(conn.userlimits_channel)

    if haskey(limits, "enabledMaxTimeout") && limits["enabledMaxTimeout"]
        return limits["maxTimeout"]
    end

    return DEFAULT_TIME_LIMIT
end

