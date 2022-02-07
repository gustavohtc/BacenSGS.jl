using BacenSGS
using Documenter

DocMeta.setdocmeta!(BacenSGS, :DocTestSetup, :(using BacenSGS); recursive=true)

makedocs(;
    modules=[BacenSGS],
    authors="Gustavo H T Cardoso <ghtcardoso@icloud.com> and contributors",
    repo="https://github.com/gustavohtc/BacenSGS.jl/blob/{commit}{path}#{line}",
    sitename="BacenSGS.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://gustavohtc.github.io/BacenSGS.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/gustavohtc/BacenSGS.jl",
)
