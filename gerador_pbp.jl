# Extraído de: 
# Yunsong Guo, Andrew Lim, Brian Rodrigues, and Jiqing Tang. 
# Using alagrangian heuristic for a combinatorial auction problem. 
# In17th IEEEInternational Conference on Tools with Artificial 
# Intelligence (ICTAI’05),pages 5–pp. IEEE, 2005.

using Printf, DelimitedFiles

function PBP_testset(m, n, d)
    P = 1:m # Conjunto de produtos
    L = 1:n # Conjunto de lances

    # Step 1: Generate coefficient matrix A
    a = zeros(Int, m, n)
    for j in L
        for i in P
            rnd = rand(Float64)
            if rnd < d
                a[i,j] = 1
            end
        end
    end

    # Step 2: Generate prices for the products
    p = zeros(m)
    for i in P
        f = 0.9 + rand(Float64)*.2
        p[i] = sum(a[i,:])*f
    end

    # Step 3: Generate prices for the bids
    c = zeros(1,n)
    for j in L
        f = 0.9 + rand(Float64)*.2
        c[j] = sum(p[i]*a[i,j] for i in P)*f
    end

    return a, c
end


# Características do conjunto de dados
nomeBase = "Instâncias/pbp_"

m = 50 # Numero de produtos
n = 50 # Numero de lances (pacotes)
d = 0.2 # Densidade de probabilidade de um lance cobrir um produto 

# Criando e salvando o conjunto
a, c = PBP_testset(m, n, d)

outFile =  @sprintf("%s%i-%i_dens%f.txt", nomeBase, m, n, d)
P = 1:m
L = 1:n

open(outFile, "w") do io
    writedlm(io, [m n])
    writedlm(io, c)

    for i in P
        lances = Int64[]
        for j in L
            if a[i,j] == 1
                push!(lances, j)
            end
        end
        nLances = length(lances)
        writedlm(io, nLances)
        if nLances > 0
            writedlm(io, reshape(lances, 1, nLances))
        else
            writedlm(io, " ")
        end
    end
end