module BacenSGS

using HTTP, Dates, DataFrames

"""
    valores_indicador(indicador::Integer;dtInicial::Dates.Date = Date(2018),dtFinal=missing)

Retorna os valores das séries tempórais do Banco Central para o indicador (Código SGS)
"""
function valores_indicador(indicador::Integer;dtInicial::Dates.Date=Date(2018),dtFinal=missing)
    linkSgs = "http://api.bcb.gov.br/dados/serie/bcdata.sgs.$(indicador)/dados?formato=json&dataInicial=$(Dates.format(dtInicial,dateformat"dd/mm/yyyy"))&dataFinal=$(Dates.format(coalesce(dtFinal,Dates.today()),dateformat"dd/mm/yyyy"))"
    resp = HTTP.get(linkSgs,require_ssl_verification = false)
    if resp.status != 200
        return DataFrame()
    end
    r = resp.body |> String |> JSON3.read |> DataFrame
    r[!,:dt_referencia] = r.data .|> x-> Date(x,dateformat"dd/mm/yyyy")
    r[!,:indicador] .= indicador
    r[!,:vl_realizado] = r.valor .|> x->0.01parse(Float64,x)
    select(r,Not([:data,:valor]))
end


export getIndicadores



end
