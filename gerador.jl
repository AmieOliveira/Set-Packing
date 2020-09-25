using Printf, Random, DelimitedFiles

nomeBase = "Instâncias/self_"

m = 100 # Numero de produtos
n = 50 # Numero de lances (pacotes)

maxProducts = 10 #Int(m/2)
custoBase = 10
# NOTE: Estou assumindo que todos os produtos tem mesmo valor! (Nao necessariamente e o caso...)




# Conjuntos
P = 1:m # Conjunto de produtos
L = 1:n # Conjunto de lances

outFile =  @sprintf("%s%i-%i_max%i_base%i.txt", nomeBase, m, n,maxProducts, custoBase)

a = zeros(Int,m,n)
c = zeros(1,n)

for j in L
    nProducts = rand(1:maxProducts)

    products = Int64[]
    cost = 0
    for idx in 1:nProducts
        i = rand(P)
        while i ∈ products
            i = rand(P)
        end
        push!(products,i)

        a[i,j] = 1

        add = custoBase*(1 + randn(Float64))
        if add < 0
            add = 0
        end
        cost = cost + add
    end

    if cost ≤ 0
        cost = nProducts
    end
    c[j] = round(cost)

    println(sort(products), " -> ", cost)
end


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
        writedlm(io, reshape(lances, 1, nLances))
    end
end