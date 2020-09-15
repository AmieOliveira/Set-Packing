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



leilao = Model(Gurobi.Optimizer)
@variable(leilao, x[j in L] >= 0, Bin)
@constraint(leilao, disponibilidade[i in P], sum(a[i,j]*x[j] for j in L) <= 1)
@objective(leilao, Max, sum(c[j]*x[j] for j in L))

# set_optimizer_attribute(leilao, "PreCrush", 1) #Para usar UserCuts
set_optimizer_attribute(leilao, "Cuts", 0) #Desabilitar outros cortes
set_optimizer_attribute(leilao, "Presolve", 0) #Desabilitar presolve
set_optimizer_attribute(leilao, "Heuristics", 0) #Desabilitar heurística
# set_optimizer_attribute(leilao, "OutputFlag", 0) #Desabilitar log
set_optimizer_attribute(leilao, "Threads", 1) 
# set_optimizer_attribute(leilao, "NodeLimit", g_params.node_limit) #Limite de nós


# mutable struct NodeData
#     time::Float64  # in seconds since the epoch
#     node::Int
#     obj::Float64
#     bestbound::Float64
#     solutionsValue::Vector{Float64}
# end

# bbdata = NodeData[]
# 
# function infocallback(cb)
#     # Function that tracks the best bound and incumbent objective value as 
#     # the solver progresses through the branch-and-bound tree 
#     node      = MathProgBase.cbgetexplorednodes(cb)
#     obj       = MathProgBase.cbgetobj(cb)
#     bestbound = MathProgBase.cbgetbestbound(cb)
#     push!(bbdata, NodeData(time(),node,obj,bestbound, JuMP.getvalue(x)))
# end
# MOI.set(leilao, MOI.LazyConstraintCallback(), infocallback)

# solutionvalues = Vector{Float64}[]
# function infocallback(cb)# 
#     push!(solutionvalues, JuMP.getvalue(x))
# end
# MOI.set(leilao, MOI.LazyConstraintCallback(), infocallback)


optimize!(leilao)