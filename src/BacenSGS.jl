module BacenSGS

using HTTP, Dates, DataFrames,JSON3, Gumbo, StringEncodings, ProgressLogging

const SEARCH_URL = Dict("pt"=>"https://www3.bcb.gov.br/sgspub/index.jsp?idIdioma=P", "en"=>"https://www3.bcb.gov.br/sgspub/index.jsp")

function timeserie_value(indicador::Integer;dtInicial::Dates.Date=Date(2018),dtFinal=missing)
    linkSgs = "http://api.bcb.gov.br/dados/serie/bcdata.sgs.$(indicador)/dados?formato=json&dataInicial=$(Dates.format(dtInicial,dateformat"dd/mm/yyyy"))&dataFinal=$(Dates.format(coalesce(dtFinal,Dates.today()),dateformat"dd/mm/yyyy"))"
    resp = HTTP.get(linkSgs,require_ssl_verification = false)
    if resp.status != 200
        return DataFrame()
    end
    r = resp.body |> String |> JSON3.read |> DataFrame
    r[!,:dt_referencia] = r.data .|> x-> Dates.Date(x,dateformat"dd/mm/yyyy")
    r[!,:indicador] .= indicador
    r[!,:vl_realizado] = r.valor .|> x->0.01parse(Float64,x)
    select(r,Not([:data,:valor]))
end




get_tipo_busca(codigo::Integer) = ("localizarSeriesPorCodigo",4,codigo,nothing)
get_tipo_busca(str::AbstractString) = ("localizarSeriesPorTexto",6,nothing,str)
function _get_params(searchMethod,tipo,codigo,texto)
    Dict(    
        "method"=>searchMethod,
        "periodicidade"=>4,
        "codigo"=>codigo,
        "fonte"=>341,
        "texto"=>texto,
        "hdFiltro"=>nothing,
        "hdOidGrupoSelecionado"=>nothing,
        "hdSeqGrupoSelecionado"=>nothing,
        "hdNomeGrupoSelecionado"=>nothing,
        "hdTipoPesquisa"=>tipo,
        "hdTipoOrdenacao"=>0,
        "hdNumPagina"=>nothing,
        "hdPeriodicidade"=>"Todas",
        "hdSeriesMarcadas"=>nothing,
        "hdMarcarTodos"=>nothing,
        "hdFonte"=>nothing,
        "hdOidSerieMetadados"=>nothing,
        "hdNumeracao"=>nothing,
        "hdOidSeriesLocalizadas"=>nothing,
        "linkRetorno"=>"/sgspub/consultarvalores/telaCvsSelecionarSeries.paint",
        "linkCriarFiltros"=>"/sgspub/manterfiltros/telaMfsCriarFiltro.paint",
    )
end



function init_search_session(language="pt")
    session = HTTP.get(SEARCH_URL[language]; cookies = true)
end

function serialize_form(params)
    r = []
    for k in keys(params)
        push!(r,"$(k)=$(params[k]==nothing ? "" : params[k])")
    end
    join(r,"&")
end

"""
    function search_timeseries(query)

Localiza séries por `query` - código(Integer) ou texto(String)
"""
function search_timeseries(query)
    init_search_session()
    (searchMethod, tipo,codigo,texto) = get_tipo_busca(query)
    url = "https://www3.bcb.gov.br/sgspub/localizarseries/localizarSeries.do?"
    params = _get_params(searchMethod,tipo,codigo,texto)
    sf = serialize_form(params) 
    r = HTTP.post(url*"&$sf",[],cookies=true)
    decode(r.body,enc"Latin1") |> parse_resp_timeseries
end

"""
    function parse_resp_timeseries(resp)

Localiza campos a partir da resposta da query de times series
"""
function parse_resp_timeseries(resp)
    html = replace(replace(replace(resp,"\n"=>""),"\t"=>""),"\r"=>"") |> x-> replace(x, r".+(<table[^>]+id=.tabelaSeries.+</table[^>]*>).*"=>s"\1") |> parsehtml
    reduce(html.root.children[2].children[1].children[2].children,init=DataFrame()) do a,b
        push!(a,(;
            id=parse(Int64,b.children[2].children[1].text),
            descrição=b.children[3].children[1].text,
            periodicidade=b.children[5].children[1].children[1].text
        ))
    end

end


"""
    function timeseries_values(timeseries::Vector;dtInicial::Dates.Date=Date(2018),dtFinal=missing, progress=nothing)

Retorna os valores de um conjunto de `timeseries` a partir de uma data inicial `dtInicial` até a data final `dtFinal`
"""
function timeseries_values(timeseries::Vector;dtInicial::Dates.Date=Date(2018),dtFinal=missing)
    ProgressLogging.progress() do id
        progresso = 0.0
        reduce(timeseries,init=DataFrame()) do a,b
            progresso += 1/length(timeseries)
            r = append!(a,timeserie_value(b;dtInicial=dtInicial,dtFinal=dtFinal))
            @info "Downloading series: " progress=progresso _id=id
            r
        end
    end
end



export timeserie_value, timeseries_values, search_timeseries

end
