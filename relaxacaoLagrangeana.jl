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

global m, n, P, L, a, c



function subproblema_lagrangeano(u)
    # Retorna: z(u), x_up e s
    #ml = Model(Gurobi.Optimizer)
    #@variable(ml, x[j in L], Bin)
    #@objective(ml, Max, sum(c[j]*x[j] for j in L) + sum( u[i]*( 1 - sum(a[i,j]*x[j] for j in L) ) for i in P) )
    #optimize!(ml)
    #return objective_value(ml), value.(x), s

    x = zeros(n)
    cl_MaxIdx = 1

    c_l = zeros(n)

    for j in L
        c_l[j] = c[j] - sum(a[i,j]*u[i] for i in P)

        if c_l[j] > 0 
            x[j] = 1
        end

        if c_l[j] > c_l[cl_MaxIdx]
            cl_MaxIdx = j
        end
    end
    if c_l[cl_MaxIdx] < 0
        x[cl_MaxIdx] = 1
    end

    s = zeros(m)
    for i in P
        s[i] = 1 - sum(a[i,j]*x[j] for j in L)
    end

    # z = sum(c[j]*x[j] for j in L) + sum( u[i]*( 1 - sum(a[i,j]*x[j] for j in L) ) for i in P)
    z = sum(c_l[j]*x[j] for j in P) + sum(u[i] for i in P)

    return z, x, s
end

function limite_inferior(custos, x_dual=[])
    # Retorna o z_low e o x_low
    x = zeros(m)

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
        tmp = zeros(m)

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
    # Retorna uma booleana que diz se x_up e otimo para o PEC
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
    k = 0
    maxIter = 1000
    p_i = 2
    u = zeros(m)

    eps = 0.1

    z_low, x_low = limite_inferior(c)

    z_u_best = 9999999
    x_u_best = zeros(n)
    k_best = 0

    z_l_best = z_low
    x_best = x_low

    limInfType = "default"  # Pode ser "complementares" # NAO TESTADO


    while k < maxIter
        # Resolução do subproblema lagrangeano
        z_u, x_up, s = subproblema_lagrangeano(u)
        #println("Limite dual: ", z_u, "(", x_up, ")")

        # Verificando se houve melhora
        if z_u < z_u_best
            z_u_best = z_u
            x_u_best = x_up
            k_best = k
            println("k_best: ", k_best)
            println("Novo z_up: ", z_u_best, " (", x_u_best, ")")
        end
        
        # Atualizando o limite limite_inferior
        if (k%trunc(Int64, maxIter/10) == 0) && (k ≠ 0)
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
                x_best = x_low # NOTE: Prestar atencao, pq se x_up mudar x_best tb vai mudar
                println("Atualizado z_low: ", z_l_best, " (", x_best, ")")
            end
        end

        # Condições de otimalidade
        if z_u_best - z_l_best < 1
            println("Parando por otimalidade (z_up == z_low)")
            break   # (z = z_low)
        end
        if check(x_up, u)
            println("Parando por otimalidade (x_up é ótimo)")
            break
        end

        # Reduzindo do p_i
        if k - k_best == trunc(Int64, maxIter/20)
            p_i = p_i/2
            k_best = k
            #println("Atualizado pi (k=", k,")")
            
            if p_i < 0.0001
                println("Parando por pi pequeno")
                break   # Programa nao consegue otimizar mais
            end
        end

        # Atualizando o tamanho do passo e os multiplicadores de lagrange
        t = p_i*(z_u_best - z_l_best)/sum(s.^2)
        for j in L
            u[j] = max(0, u[j] - t*(1+eps)*s[j]) # NOTE: Verificar!!! Se for a direcao oposta a de melhora mesmo, tem que ser menos
        end

        #println("Novos multiplicadores: ", u)
        #println(s)
        #println("")

        k = k + 1
    end

    println("Iteração: ", k)

    return z_l_best, x_best
end


lagrangeana()