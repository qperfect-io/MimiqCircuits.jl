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

# maximum number of samples allowed
const MAX_SAMPLES = 2^16

# default value for the number of samples
const DEFAULT_SAMPLES = 1000

# minimum and maximum bond dimension allowed
const MIN_BONDDIM = 1
const MAX_BONDDIM = 2^12
const MIN_ENTDIM = 4
const MAX_ENTDIM = 64

# default bond dimension
const DEFAULT_BONDDIM = 256
const DEFAULT_ENTDIM = 16

# default time limit (in minutes)
const DEFAULT_TIME_LIMIT = 30

# default algorithm
const DEFAULT_ALGORITHM = "auto"

const CIRCUIT_FNAME = "circuit"
const EXTENSION_PROTO = "pb"
const TYPE_PROTO = "proto"
const TYPE_QASM = "qasm"
const TYPE_STIM = "stim"
const EXTENSION_QASM = "qasm"
const EXTENSION_STIM = "stim"

const RESULTS_FNAME = "results.json"
