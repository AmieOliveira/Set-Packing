using JuMP, Gurobi, DelimitedFiles, MathProgBase

path = "Instâncias/toy2.txt"
#path = "Instâncias/pb_100rnd0100.dat"

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

neighbors = Array{Int64}[] #Array{Array{Int64}, n} #Array{Array{Int64}}([],1,4)
for j in L
    ngs = Int64[]
    for i in P
        if a[i,j] == 1
            if sum(a[i,:]) > 1
                for j2 in L
                    if a[i,j2] == 1 && j2 != j && j2 ∉ ngs
                        append!(ngs, [j2])
                    end
                end
            end
        end
    end
    #println(ngs)
    append!(neighbors, [ngs])
end

# Bron-Kerbosch Algorithm
function find_cliques(clique, candidatos, excluidos, output)
    println("Iniciando funcao: ", clique, ", ", candidatos, ", ", excluidos)
    if candidatos == [] && excluidos == []
        push!(output, clique)
        println("Fechou um clique: ", clique)
        return
    end
    # TODO: pivô
    for v ∈ candidatos[:] #candidatos
        println(v, candidatos)
        R2 = clique ∪ [v]
        P2 = candidatos ∩ neighbors[v]
        X2 = excluidos ∩ neighbors[v]
        println("Call for ", R2, ", ", P2, ", ", X2)
        find_cliques(R2, P2, X2, output)
        filter!(e->e!=v, candidatos)
        # NOTE: se fosse iterar encima da propria lista candidatos, teria que alterar desta forma:
        #candidatos = filter(e->e!=v, candidatos) 
        # Nao altera a lista original, então não estraga os elementos da iteração
        excluidos = excluidos ∪ [v]
        println("New data: ", clique, ", ", candidatos, ", ", excluidos)
    end
end


clique = Int64[]
excluidos = Int64[]
candidatos = Array(L)

out = Array{Int64}[]

find_cliques(clique, candidatos, excluidos, out)

println(out)