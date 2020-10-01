using JuMP, Gurobi, DelimitedFiles

path = "Instâncias/inst.txt"

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

    if nLances > 0
        for lance in 1:nLances 
            j = readdlm(path)[2*i+2,lance]
            a[i,j] = 1
        end
    end
end


function subproblema_lagrangeano(u)
    # Retorna o limitante superior obtido como resultado do subproblema
    #  lagrangeano, bem como a seleção de lances x utilizadas nessa solução

    x = zeros(Int64, n)
    
    z = 0
    maxCl = -99999
    maxClIdx = 0

    for j in L
        tmp = c[j] - sum(a[i,j]*u[i] for i in P)
        if tmp > 0
            x[j] = 1
            z = z + tmp
        end
        if maxCl < tmp
            maxCl = tmp
            maxClIdx = j
        end
    end
    if maxCl < 0
        x[maxClIdx] = 1
    end

    for i ∈ P
        z = z + u[i]
    end

    return z, x
end

function limite_inferior(custos, x_dual=[])
    # Retorna uma solução viável para um problema (e, portanto, um 
    #  limitante inferior)

    x = zeros(n)

    # Organizar elementos com relação aos pesos
    idxs = sortperm(custos)
    if ~isempty(x_dual)
        tmpIn = []
        tmpOut = []

        for j in idxs
            if x_dual[j] == 1
                tmpIn = [tmpIn; j]
            else
                tmpOut = [tmpOut; j]
            end
        end

        idxs = [tmpIn, tmpOut]
    end

    # Construir o limitante
    restricoes = zeros(m)   # Uma restricao por produto. 
    # Como x é um vetor nulo, ate agora todas tem valor zero (e, 
    # consequentemente, nenhuma é violada)

    for j in idxs
        tmp = zeros(Int64, m)

        viavel = true
        for i in P
            tmp[i] = a[i,j]
            if restricoes[i] + tmp[i] > 1
                viavel = false
                break
            end
        end

        if viavel
            x[j] = 1
            restricoes = restricoes + tmp
        end
    end

    z = sum(c[j]*x[j] for j in L)
    # Nao preciso calcular durante a escolha de x, porque a 
    # adicao de um lance sempre aumenta o valor de z

    # NOTE: Possivel implementar uma busca local aqui!

    return z, x
end

function check(x_up, u)
    # Retorna uma booleana que diz se x_up e otimo para o PEC, 
    #  segundo as condições de complementariedade-folga
    viavel = true
    for i in P
        if sum(a[i,j]*x_up[j] for j in L) > 1
            viavel = false
            break
        end
    end

    z1 = sum(c[j]*x_up[j] for j in L)
    z2 = sum(c[j]*x_up[j] for j in L) + sum( u[i]*( 1 - sum(a[i,j]*x_up[j] for j in L) ) for i in P)
    compl = (z1 == z2) 

    return viavel && compl
end

# ----------------------


# Algoritmo de otimização lagrangeana

function lagrangeana()
    maxIter = 1000
    p_i = 2
    u = zeros(m)

    eps = 0.1
    pi_min = 0.0001

    z_low, x_low = limite_inferior(c)

    z_u_best = 9999999
    x_u_best = zeros(n)
    k_best = 0
    improve = 0

    z_l_best = z_low
    x_best = x_low

    limInfType = "default"  # Pode ser "complementares", mas isso NAO FOI TESTADO


    for k ∈ 1:maxIter
        # Resolução do subproblema lagrangeano
        z_u, x_up = subproblema_lagrangeano(u)

        # Verificando se houve melhora
        if z_u < z_u_best
            z_u_best = z_u
            x_u_best = x_up
            k_best = k
            improve = 0
            println("k_best: ", k_best)
            println("Novo z_up: ", z_u_best)
        else
            improve += 1
        end
        
        # Atualizando o limite limite_inferior
        custo = zeros(n)
        x_dual = []
        if limInfType == "default"
            for j in L
                custo[j] = c[j] - sum(a[i,j]*u[i] for i in P)
                custo[j] = custo[j]/(sum(a[i,j] for i in P))
            end
        elseif limInfType == "complementares"
            custo = c
            for j in L
                custo[j] = custo[j]/(sum(a[i,j] for i in P))
            end
            x_dual = x_up
        end
        z_low, x_low = limite_inferior(custo, x_dual)

        # Verificando se houve melhora
        if z_low > z_l_best
            z_l_best = z_low
            x_best = x_low 
            println("Atualizado z_low: ", z_l_best, " - iteração ", k)
        end

        # Condições de otimalidade
        if z_u_best - z_l_best < 1
            println("Parando por otimalidade (z_up == z_low) - iteração ", k)
            break   # (z = z_low)
        end
        if check(x_up, u)
            println("Parando por otimalidade (x_up é ótimo) - iteração ", k)
            z_l_best = z_u
            x_best = x_up
            break
        end

        # Reduzindo do p_i
        if improve >= maxIter/20
            p_i = p_i/2
            improve = 0
            
            if p_i < pi_min
                println("Parando por pi pequeno (iteração ", k, ")")
                break   # Programa nao consegue otimizar mais
            end
        end

        # Atualizando o tamanho do passo e os multiplicadores de lagrange
        s = zeros(m)
        sqrSum = 0
        for i in P
            s[i] = 1 - sum(a[i,j]*x_up[j] for j in L)
            sqrSum += s[i]^2
        end
        t = p_i*(z_u - z_low)/sqrSum
        if t < pi_min
            println("Parando por t pequeno (iteração ", k, ")")
            break
        end

        for i in P
            u[i] = max(0, u[i] - t*s[i])
        end
    end

    return z_l_best, x_best
end


time = @elapsed (out = lagrangeana())

println("Melhor resultado: ", out)
println("Tempo levado: ", time)