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

module MimiqCircuits

using Reexport
using SHA
using JSON
using MimiqLink
import Pkg

@reexport using MimiqCircuitsBase
@reexport using MimiqLink:
    connect,
    savetoken,
    loadtoken,
    isjobdone,
    isjobfailed,
    isjobstarted,
    requestinfo,
    stopexecution,
    deletefiles,
    requests,
    printrequests,
    Execution,
    QPERFECT_CLOUD,
    QPERFECT_DEV,
    MimiqConnection,
    PlanqkConnection

export execute
export getinputs
export getinput
export getresults
export getresult

export saveresults
export loadresults

export QCSError

include("constants.jl")
include("utils.jl")
include("execute.jl")
include("get.jl")
include("deprecated.jl")

"""
    saveresults(file, results)

Save results to a given file.
"""
saveresults(f::AbstractString, res::QCSResults) = saveproto(f, res)

"""
    loadresults(file)

Load results from a given file.
"""
loadresults(f::AbstractString) = loadproto(f, QCSResults)

end # module MimiqCircuits
