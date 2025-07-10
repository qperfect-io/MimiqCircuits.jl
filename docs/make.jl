using Documenter
using DocumenterCitations
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
        "Installation" => "manual/installation.md",
        #"Quick Examples" => "manual/quick_examples.md",
        "Overview" => "manual/overview.md",
        "Circuits" => "manual/circuits.md",
        "Unitary Gates" => "manual/unitary_gates.md",
        "Non-unitary Operations" => "manual/non_unitary_ops.md",
        "Noise" => "manual/noise.md",
        "Symbolic Operations" => "manual/symbolic_ops.md",
        "Statistical Operations" => "manual/statistical_ops.md",
        "Z-register operation" => "manual/zops.md",
        "hamiltonian" => "manual/hamiltonian.md",
        "Special Operations" => "manual/special_ops.md",
        "Simulating Circuits" => "manual/simulation.md",
        "Cloud Execution" => "manual/remote_execution.md",
        "Import & Export Circuits" => "manual/import_export.md",
        "Special Topics" => "manual/special_topics.md",
    ],
    # "Use cases" => ["VQE" => "usecases/vqe.md"],
    "Library"=>[
        "Outline" => "library/outline.md",
        "MimiqCircuits" => "library/mimiqcircuits.md",
        "MimiqLink" => "library/mimiqlink.md",
        "MimiqCircuitsBase" => [
            "library/mimiqcircuitsbase/general.md",
            "library/mimiqcircuitsbase/circuits.md",
            "library/mimiqcircuitsbase/operations.md",
            "library/mimiqcircuitsbase/standard.md",
            "library/mimiqcircuitsbase/generalized.md",
            "library/mimiqcircuitsbase/other.md",
            "library/mimiqcircuitsbase/noise.md",
            "library/mimiqcircuitsbase/operators.md",
            "library/mimiqcircuitsbase/bitstrings.md",
            "library/mimiqcircuitsbase/results.md",
            "library/mimiqcircuitsbase/hamiltonian.md",
            "library/mimiqcircuitsbase/aliases.md"
        ],
        "Internals" => "library/internals.md",
        "Function Index" => "library/function_index.md",
    ],
    "References"=>"references.md",
]

bib = CitationBibliography(joinpath(@__DIR__, "src/references.bib"))

makedocs(;
    sitename="MimiqCircuits.jl",
    authors="QPerfect",
    modules=[MimiqCircuits, MimiqLink, MimiqCircuitsBase],
    format=format,
    pages=pages,
    clean=true,
    checkdocs=:exports,
    plugins=[bib],
)

deploydocs(
    repo="github.com/qperfect-io/MimiqCircuits.jl.git",
    forcepush=true,
    push_preview=true,
    devbranch="main",
)
