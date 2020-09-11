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


leilao = Model(Gurobi.Optimizer)
@variable(leilao, x[j in L] >= 0, Bin)
@constraint(leilao, disponibilidade[i in P], sum(a[i,j]*x[j] for j in L) <= 1)
@objective(leilao, Max, sum(c[j]*x[j] for j in L))

optimize!(leilao)

function print_resultado()
    for j in L
        if value(x[j]) == 1
            println("Lance ", j, ": ", value(x[j]))
        end
    end
    println("Valor total das vendas: ", objective_value(leilao))
end

print_resultado()