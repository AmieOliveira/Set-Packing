using JuMP, Gurobi, DelimitedFiles, MathProgBase

#path = "Instâncias/inst.txt"
path = "Instâncias/pb_100rnd0100.dat"

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
    if candidatos == [] && excluidos == []
        push!(output, clique)
        return
    end
    # TODO: pivô
    for v ∈ candidatos[:] #candidatos
        R2 = clique ∪ [v]
        P2 = candidatos ∩ neighbors[v]
        X2 = excluidos ∩ neighbors[v]
        find_cliques(R2, P2, X2, output)
        
        filter!(e->e!=v, candidatos)
        # NOTE: se fosse iterar encima da propria lista candidatos, teria que alterar desta forma:
        #candidatos = filter(e->e!=v, candidatos) 
        # Nao altera a lista original, então não estraga os elementos da iteração
        excluidos = excluidos ∪ [v]
    end
end



# Relação dos cliques do grafo de conflito
clique = Int32[]
excluidos = Int64[]
candidatos = Array(L)
out = Array{Int32}[]

find_cliques(clique, candidatos, excluidos, out)

println(out)


# Algoritmo de corte
function callbacks(cb_data, cb_where)
    # if cb_where ≠ CB_MESSAGE    # Não está imprimindo mensagem de log
    #     println("ONDE ESTOU: ", cb_where)
    # end
    if cb_where == CB_MIPNODE
        eps = 0.0001
        #println("**** Novo nó! ****");
        #println("Nó: ", cbget_mipnode_nodcnt(cb_data, cb_where))
        status = cbget_mipnode_status(cb_data, cb_where)
        if status == 2 #optimal
            x_val = cbget_mipnode_rel(cb_data, cb_where)
            #println(x_val)

            for cliq ∈ out
                soma = 0
                for j ∈ cliq
                    soma += x_val[j]
                end
                if soma > 1 + eps
                    # Essa restrição foi violada
                    println("Restrição violada!! Clique: ", cliq)
                    val = ones(length(cliq))
                    cbcut(cb_data, cliq, val, '<', 1.0+eps)
                end
            end
        end
    end
end


# Modelo do problema
leilao = Model(
    optimizer_with_attributes(
        Gurobi.Optimizer, "PreCrush" => 1, "Cuts" => 0, "Presolve" => 0, "Heuristics" => 0.0
        )
)
@variable(leilao, x[j in L] >= 0, Bin)
@constraint(leilao, disponibilidade[i in P], sum(a[i,j]*x[j] for j in L) <= 1)
@objective(leilao, Max, sum(c[j]*x[j] for j in L))

MOI.set(leilao, Gurobi.CallbackFunction(), callbacks)

optimize!(leilao)

