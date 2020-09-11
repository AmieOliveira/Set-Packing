using DelimitedFiles

inFile = "Instâncias/Original/pb_100rnd0100.dat"
outFile = "Instâncias/pb_100rnd0100.txt"

m = readdlm(inFile)[1,1] # Numero de produtos
n = readdlm(inFile)[1,2] # Numero de lances (pacotes)

P = 1:m # Conjunto de produtos
L = 1:n # Conjunto de lances

c = zeros(1,n)
for j in L
    c[j] = readdlm(inFile)[2,j]
end

a = zeros(Int, m, n)
for i in P
    nLances = readdlm(inFile)[2*i+1,1]

    for lance in 1:nLances 
        j = readdlm(inFile)[2*i+2,lance]
        a[i,j] = 1
    end
end

open(outFile, "w") do io
    writedlm(io, [m n])
    writedlm(io, a)
    writedlm(io, c)
end