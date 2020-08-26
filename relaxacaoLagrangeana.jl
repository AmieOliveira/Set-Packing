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



function subproblema_lagrangeano(u)
    # Retorna: z(u), x_up e s
    #ml = Model(Gurobi.Optimizer)
    #@variable(ml, x[j in L], Bin)
    #@objective(ml, Max, sum(c[j]*x[j] for j in L) + sum( u[i]*( 1 - sum(a[i,j]*x[j] for j in L) ) for i in P) )
    #optimize!(ml)
    #return objective_value(ml), value.(x), s

    x = zeros(n)
    cl_Max = -9999999
    cl_MaxIdx = 0
    for j in L
        c_l = c[j] - sum(u[i] for i in P)
        if c_l > cl_Max
            cl_Max = c_l
            cl_MaxIdx = j
        end

        if c_l > 0 
            x[j] = 1
        end
    end
    if cl_Max < 0
        x[cl_MaxIdx] = 1
    end

    s = zeros(m)
    for i in P
        s[i] = 1 - sum(a[i,j]*x[j] for j in L)
    end

    z = sum(c[j]*x[j] for j in L) + sum( u[i]*( 1 - sum(a[i,j]*x[j] for j in L) ) for i in P)
    # TODO: Reescrever de maneira menos ineficiente

    return z, x, s
end

function limite_inferior(u)
    # Retorna o z_low e o x_low
    
    # TODO
    return 0, zeros(m)
end

function check(x_up)
    # Retorna uma booleana que diz se x_up e otimo para o PEC

    # TODO
    return false
end

# ----------------------


# Algoritmo de otimização lagrangeana

function lagrangeana()
    k = 0
    maxIter = 1000
    p_i = 2
    u = zeros(m)

    eps = 0.1

    z_low, x_low = limite_inferior(u)

    z_u_best = 9999999
    k_best = 0

    z_l_best = z_low
    x_best = zeros(m)


    while k < maxIter
        # Resolução do subproblema lagrangeano
        z_u, x_up, s = subproblema_lagrangeano(u)

        # Verificando se houve melhora
        if z_u < z_u_best
            z_u_best = z_u
            k_best = k
            println("k_best", k_best)
        end
        
        # Atualizando o limite limite_inferior
        if k%trunc(Int64, maxIter/10) == 0
            z_low, x_low = limite_inferior(u)
            println("Atualizado z_low: ", z_low)

            # Verificando se houve melhora
            if z_low > z_l_best
                z_l_best = z_low
                x_best = x_low # NOTE: Prestar atencao, pq se x_up mudar x_best tb vai mudar
            end
        end

        # Condições de otimalidade
        if z_u - z_low < 1
            println("Parando por otimalidade (z == z_low)")
            break   # (z = z_low)
        end
        if check(x_up)
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
        u = u + t*(1+eps).*s

        k = k + 1
    end

    return z_l_best, x_best
end


lagrangeana()