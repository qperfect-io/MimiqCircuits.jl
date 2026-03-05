using Documenter
using Dates

using MimiqCircuits
using MimiqCircuitsBase
using MimiqLink

DocMeta.setdocmeta!(MimiqCircuits, :DocTestSetup, :(using MimiqCircuits); recursive=true)
DocMeta.setdocmeta!(
    MimiqCircuitsBase,
    :DocTestSetup,
    :(using MimiqCircuitsBase);
    recursive=true,
)
DocMeta.setdocmeta!(MimiqLink, :DocTestSetup, :(using MimiqLink); recursive=true)

if !haskey(ENV, "MIMIQUSER")
    error("Please define the MIMIQUSER environment with your MIMIQ username.")
end

if !haskey(ENV, "MIMIQPASS")
    error("Please define the MIMIQUSER environment with your MIMIQ password.")
end

if !haskey(ENV, "MIMIQOUTPUTFORMAT") || ENV["MIMIQOUTPUTFORMAT"] == "HTML"
    format = Documenter.HTML(
        collapselevel=1,
        prettyurls=get(ENV, "CI", nothing) == "true",
        footer="Copyright 2021-$(year(now())) QPerfect. All rights reserved.",
        assets=String[],
    )
elseif ENV["MIMIQOUTPUTFORMAT"] == "PDF"
    using tectonic_jll: tectonic
    format = Documenter.LaTeX(platform="tectonic", tectonic=tectonic())
else
    error("Unrecognized output format $(ENV["MIMIQOUTPUTFORMAT"])")
end

pages = Any[
    "MIMIQ Documentation"=>"index.md",
    "Quick start"=>"quick_start.md",
    "Manual"=>[
        "Getting Started" => [
            "Installation" => "manual/installation.md",
            "Overview" => "manual/overview.md",
        ],
        "Core Concepts" => [
            "Circuits" => "manual/circuits.md",
            "Hamiltonians" => "manual/hamiltonian.md",
        ],
        "Operations" => [
            "Unitary Gates" => "manual/unitary_gates.md",
            "Non-unitary Operations" => "manual/non_unitary_ops.md",
            "Noise" => "manual/noise.md",
            "Symbolic Operations" => "manual/symbolic_ops.md",
            "Statistical Operations" => "manual/statistical_ops.md",
            "Z-register operation" => "manual/zops.md",
            "Special Operations" => "manual/special_ops.md",
        ],
        "Simulation & Execution" => [
            "Simulating Circuits" => "manual/simulation.md",
            "Simulation Parameters" => "manual/simulation_parameters.md",
            "Cloud Execution" => "manual/remote_execution.md",
        ],
        "Advanced Topics" => [
            "Import & Export Circuits" => "manual/import_export.md",
            "Circuit DSL" => "manual/dsl.md",
            "Special Topics" => "manual/special_topics.md",
            "Compilation & Optimization" => [
                "Simplifications" => "manual/compilation/simplifications.md",
                "Rewrites and Decompositions" => "manual/compilation/decompositions.md",
                "Custom Decompositions" => "manual/compilation/custom_decompositions.md",
            ],
        ],
    ],
    "Use cases"=>[
        "VQE" => "usecases/vqe.md",
        "Circuit Tester" => "usecases/circuit_tester.md",
    ],
    "API Reference"=>[
        "Outline" => "library/outline.md",
        "MimiqCircuits" => "library/mimiqcircuits.md",
        "MimiqLink" => "library/mimiqlink.md",
        "MimiqCircuitsBase" => [
            "library/mimiqcircuitsbase/general.md",
            "library/mimiqcircuitsbase/circuits.md",
            "library/mimiqcircuitsbase/operations.md",
            "library/mimiqcircuitsbase/standard.md",
            "library/mimiqcircuitsbase/multiqubit.md",
            "library/mimiqcircuitsbase/generalized.md",
            "library/mimiqcircuitsbase/other.md",
            "library/mimiqcircuitsbase/noise.md",
            "library/mimiqcircuitsbase/operators.md",
            "library/mimiqcircuitsbase/zops.md",
            "library/mimiqcircuitsbase/bitstrings.md",
            "library/mimiqcircuitsbase/results.md",
            "library/mimiqcircuitsbase/simplifications.md",
            "library/mimiqcircuitsbase/decompositions.md",
            "library/mimiqcircuitsbase/aliases.md"
        ],
        "Internals" => "library/internals.md",
        "Function Index" => "library/function_index.md",
    ],
]

makedocs(;
    sitename="MimiqCircuits.jl",
    authors="QPerfect",
    modules=[MimiqCircuits, MimiqLink, MimiqCircuitsBase],
    format=format,
    pages=pages,
    clean=true,
    checkdocs=:exports,
    warnonly=true,
)

deploydocs(
    repo="github.com/qperfect-io/MimiqCircuits.jl.git",
    forcepush=true,
    push_preview=true,
    devbranch="main",
)
