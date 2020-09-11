using JuMP, Gurobi, DelimitedFiles

path = "inst.txt"

m = readdlm(path)[1,1] # Numero de produtos
n = readdlm(path)[1,2] # Numero de lances (pacotes)

# Conjuntos
P = 1:m # Conjunto de produtos
L = 1:n # Conjunto de lances

a = zeros(Int,m,n)
c = zeros(n)

for j in L
    c[j] = readdlm(path)[2,j]
end

for i in P
    nLances = readdlm(path)[2*i+1,1]

    for lance in 1:nLances 
        j = readdlm(path)[2*i+2,lance]
        a[i,j] = 1
    end
end



function relaxacaoLinear(fixos, printValues=false)
    leilao = Model(Gurobi.Optimizer)
    @variable(leilao, 1 ≥ x[j in L] ≥ 0)
    @constraint(leilao, disponibilidade[i in P], sum(a[i,j]*x[j] for j in L) <= 1)
    
    for j in L
        if fixos[j] != -1
            @constraint(leilao, fixado[j], x[j] == fixos[j])
        end
    end

    @objective(leilao, Max, sum(c[j]*x[j] for j in L))

    optimize!(leilao)

    if printValues
        println("Resultado da relaxacao linear: ", objective_value(leilao))
        print("  Seleção: ")
        for j in L
            print(value(x[j]), ", ")
        end
        println("")
    end

    return objective_value(leilao), values(x)
end


mutable struct Conjunto 
    meuIdx::Int64
    pai::Int64
    filhos::Array{Int64}
    limUp::Float64
    limDn::Float64
    fixos::Array{Int64, n}
end




f = zeros(Int, n) .- 1
zl, xl = relaxacaoLinear(f, true)



# TODO
set_optimizer_attribute(model, "PreCrush", 1) #Para usar UserCuts
set_optimizer_attribute(model, "Cuts", 0) #Desabilitar outros cortes
set_optimizer_attribute(model, "Presolve", 0) #Desabilitar presolve
set_optimizer_attribute(model, "Heuristics", 0) #Desabilitar heurística
# set_optimizer_attribute(model, "OutputFlag", 0) #Desabilitar log
set_optimizer_attribute(model, "Threads", 1) 
set_optimizer_attribute(model, "NodeLimit", g_params.node_limit) #Limite de nós