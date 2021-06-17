using Documenter
using ReadStatTables
using CategoricalArrays

DocMeta.setdocmeta!(ReadStatTables, :DocTestSetup, :(using ReadStatTables, CategoricalArrays))

makedocs(
    modules = [ReadStatTables],
    format = Documenter.HTML(
        canonical = "https://junyuan-chen.github.io/ReadStatTables.jl/stable/",
        prettyurls = get(ENV, "CI", nothing) == "true",
        edit_link = "main"
    ),
    sitename = "ReadStatTables.jl",
    authors = "Junyuan Chen",
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Getting Started" => "man/getting-started.md",
            "Table Interface" => "man/table-interface.md",
            "Value Labels" => "man/value-labels.md",
            "Date and Time Values" => "man/date-and-time-values.md"
        ],
        "About" => [
            "License" => "license.md"
        ]
    ],
    workdir = joinpath(@__DIR__, "..")
)

deploydocs(
    repo = "github.com/junyuan-chen/ReadStatTables.jl.git",
    devbranch = "main"
)
