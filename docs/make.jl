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

format = Documenter.HTML(
    collapselevel=2,
    prettyurls=get(ENV, "CI", nothing) == "true",
    footer="Copyright 2021-$(year(now())) QPerfect. All rights reserved.",
)

pages = Any[
    "Introduction"=>"index.md",
    "Installation"=>"installation.md",
    "Tutorial"=>"tutorial.md",
    "Manual"=>[
        "Circuit execution" => "manual/execution.md",
        "OpenQASM" => "manual/openqasm.md",
    ],
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
            "library/mimiqcircuitsbase/bitstrings.md",
            "library/mimiqcircuitsbase/results.md",
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
    versions=["stable" => "v^", "v#.#.#", "dev" => "dev"],
    forcepush=true,
    push_preview=true,
    devbranch="main",
)
