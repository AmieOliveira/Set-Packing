using Random, DelimitedFiles

nomeBase = "Instâncias/"

m = 20 # Numero de produtos
n = 10 # Numero de lances (pacotes)

maxProducts = Int(m/2)
custoBase = 10
# NOTE: Estou assumindo que todos os produtos tem mesmo valor! (Nao necessariamente e o caso...)




# Conjuntos
P = 1:m # Conjunto de produtos
L = 1:n # Conjunto de lances

outFile = ""

a = zeros(Int,m,n)
c = zeros(n)

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
    end
    sort!(products)

    cost = 0
    for i in products
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
    c[j] = Int(cost)

    #println(products, " -> ", cost)
end