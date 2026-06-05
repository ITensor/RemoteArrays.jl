using Documenter: Documenter, DocMeta, deploydocs, makedocs
using RemoteArrays: RemoteArrays

DocMeta.setdocmeta!(
    RemoteArrays, :DocTestSetup, :(using RemoteArrays); recursive = true
)

include("make_index.jl")

makedocs(;
    modules = [RemoteArrays],
    authors = "ITensor developers <support@itensor.org> and contributors",
    sitename = "RemoteArrays.jl",
    format = Documenter.HTML(;
        canonical = "https://itensor.github.io/RemoteArrays.jl",
        edit_link = "main",
        assets = ["assets/favicon.ico", "assets/extras.css"]
    ),
    pages = ["Home" => "index.md", "Reference" => "reference.md"]
)

deploydocs(;
    repo = "github.com/ITensor/RemoteArrays.jl", devbranch = "main", push_preview = true
)
