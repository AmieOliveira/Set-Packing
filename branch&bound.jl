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
    for i in P
        a[i,j] = readdlm(path)[i+1,j]
    end
    c[j] = readdlm(path)[m+2,j]
end
#println(a)



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