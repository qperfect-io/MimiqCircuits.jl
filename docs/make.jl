using Documenter
using Dates

using MimiqCircuits
import MimiqCircuitsBase
import MimiqLink

DocMeta.setdocmeta!(MimiqCircuits, :DocTestSetup, :(using MimiqCircuits); recursive=true)
DocMeta.setdocmeta!(MimiqCircuitsBase, :DocTestSetup, :(using MimiqCircuitsBase); recursive=true)
DocMeta.setdocmeta!(MimiqLink, :DocTestSetup, :(using MimiqLink); recursive=true)

format = Documenter.HTML(
    collapselevel=2,
    prettyurls=get(ENV, "CI", nothing) == "true",
    footer="Copyright 2021-$(year(now())) QPerfect. All rights reserved."
)

pages = Any[
    "Home"=>"index.md",
    "About"=>"about.md",
    "Getting Started"=>"getting_started.md",
    "Basics"=>"basics.md",
    "Library"=>[
        "Contents" => "library/outline.md",
        "Public" => "library/public.md",
        "Private" => "library/internals.md",
        "Function index" => "library/function_index.md"
    ]
]

makedocs(;
    sitename="MimiqCircuits.jl",
    authors="QPerfect",
    modules=[MimiqCircuits, MimiqCircuitsBase, MimiqLink],
    format=format,
    pages=pages,
    clean=true,
    checkdocs=:exports
)

deploydocs(
    repo="github.com/qperfect-io/MimiqCircuits.jl.git",
    versions=["stable" => "v^", "v#.#.#", "dev" => "dev"],
    forcepush=true,
    push_preview=true,
    devbranch="main"
)
