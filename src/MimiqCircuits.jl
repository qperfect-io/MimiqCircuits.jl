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
    Connection,
    Execution,
    QPERFECT_CLOUD,
    QPERFECT_CLOUD2

export execute
export executeqasm
export getinputs
export getresults

export saveresults
export loadresults

include("constants.jl")
include("utils.jl")
include("execute.jl")
include("executeqasm.jl")
include("get.jl")

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
