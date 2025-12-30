#! /usr/bin/env sage

import collections
R.<r,p> = QQ[]

def my_vandermonde(v, ncols=None, ring=None):
    def entries(i, j):
        return v[i]**j
    if ncols is None:
        ncols = len(v)
    return matrix(entries, nrows=len(v), ncols=ncols, ring=ring)

class MoranRule:
    @staticmethod
    def name():
        return "moran"

    @staticmethod
    def rule_from(S, u, G, states_reducer):
        PS = collections.defaultdict(Integer)
        visited_states = []
        for v in G[u]:
            Sp = list(S)
            Sp[v] = S[u]
            Sp = states_reducer[tuple(Sp)]
            PS[Sp] += (r if S[u] else 1)/G.degree(u)
            visited_states.append(Sp)
        return PS, visited_states
    
    @staticmethod
    def vars_and_vales(N):
        """NOT TRUE: Return enough values for the computation of the rational functions.
        In our case, if the matrix is of size N all functions are rational functions on r
        with degree at most N. We can agree that r^N in denominator is 1:
             a₀ + a₁r + a₂r^2 + ··· + a_n r^N
            ----------------------------------
             b₀ + b₁r + b₂r^2 + ··· +     r^N
        Then, we need 2n + 1 values or r
        """
        
        rs = flatten([
            [ Integer(i) for i in range(1,N//2+2) ],
            [ 1/(Integer(i)+2) for i in range(N//2) ],
        ])
        rs = rs[:N]

        return [{r: val} for val in rs ]
        
    @staticmethod
    def row_phi(N):
        """
             a₀ + a₁r + a₂r^2 + ··· + a_n r^N
            ----------------------------------
                       DETERMINANT

        """
        retval = [r**i for i in range(N+1)]
        
        return retval

    @staticmethod
    def row_unconditional_time(N):
        """
             a₀ + a₁r + a₂r^2 + ··· + a_n r^N
            ----------------------------------
                       DETERMINANT

        """
        retval = [r**i for i in range(N+1)]
        
        return retval
        
    @staticmethod
    def row_conditional_time(N):
        """
            AdjQ AdjQ D_w barb  <-- deg 2n
            ------------------
            DETERMINANT PhiNum
            
            Then, the numerator is 
        """
        retval = [r**i for i in range(2*N+1)]
        
        return retval

    @staticmethod
    def recover_unconditional_timenum(row):
        return MoranRule.recover_phinum(row)
    
    @staticmethod
    def recover_conditional_timenum(row):
        return MoranRule.recover_phinum(row)
    
    @staticmethod
    def recover_phinum(row):
        return sum( val * r**i for i,val in enumerate(row) )
    
class BernoulliRule:
    @staticmethod
    def name():
        return "bernoulli"

    @staticmethod
    def rule_from(S, u, G, states_reducer):
        PS = collections.defaultdict(Integer)
        if S[u]: # Mutant... proliferation occurs
            Sp = list(S)
            for v in G[u]:
                Sp[v] = 1
            Sp = states_reducer[tuple(Sp)]
            PS[Sp] += r * p
            PS[S] += r * (1-p)
            return PS, [Sp]
        else:
            visited_states = []
            for v in G[u]:
                Sp = list(S)
                Sp[v] = 0
                Sp = states_reducer[tuple(Sp)]
                PS[Sp] += 1/G.degree(u)
                visited_states.append(Sp)
            return PS, visited_states

    @staticmethod
    def vars_and_vales(N):
        #rs = [ Integer(i)+1 for i in range(N) ]
        #ps = [ 1/(Integer(i)+2) for i in range(N) ]
        rs = [ randint(1,10000) for i in range(N) ]
        ps = [ 1/randint(1,10000) for i in range(N) ]
        
        return [{r: val, p:val2} for val, val2 in zip(rs, ps)]
        
    
    @staticmethod
    def row_phi(N):
        return [(r*p)**i for i in range(N+1)]
    
    @staticmethod
    def recover_phinum(row):
        return sum(val*(r*p)**i for i,val in enumerate(row))
        
    @staticmethod
    def row_unconditional_time(N):
        """
             a₀ + a₁(rp) + a₂(rp)^2 + ··· + a_n (rp)^N-1 + c₁r + c₂r(rp) + ··· + c_n r(rp)^N-1
            ----------------------------------------------------------------------------------
                               DETERMINANT
        """
        retval = [(r*p)**i for i in range(N)]
        retval.extend([r*v for v in retval])
        
        return retval
        
    @staticmethod
    def row_conditional_time(N):
        retval = [(r*p)**i for i in range(2*N)]
        retval.extend([r*v for v in retval])

        return retval

    @staticmethod
    def recover_unconditional_timenum(row):
        N = len(row)//2
        
        F = sum(val * (r*p)**i for i,val in enumerate(row[:N]))
        F += sum(val * r * (r*p)**i for i,val in enumerate(row[N:]))
        
        return F
    
    @staticmethod
    def recover_conditional_timenum(row):
        return BernoulliRule.recover_unconditional_timenum(row)

def posibleStates(G):
    bini = lambda x : tuple( [(x >> i) & 1 for i in range(G.order())] )
    
    P = G.automorphism_group()
    
    states_reducer = {bini(u):None for u in range((1<<G.order())+1)}
    
    for u, val in states_reducer.items():
        if val is None: # Not found early
            for p in P:
                newu = tuple( u[p(i)] for i in range(G.order()) )
                states_reducer[newu] = u
 
    return states_reducer

def sparse_system_matrix(G, states_reducer, rule):
    P = {}

    remaining_states = [ states_reducer[ 
                                (0,) * i +
                                (1,) + 
                                (0,) * (G.order()-i-1)
                               ] for i in range(G.order())]
    wSs = {}
    while remaining_states:
        S = remaining_states.pop()
        if S not in P:
            wS = sum(S)
            wS = G.order() - wS + r*wS
            wSs[S] = wS

            P[S] = collections.defaultdict(Integer)
            for u in G:
                PS, visited_states = rule.rule_from(S, u, G, states_reducer)
                for Sp, val in PS.items():
                    P[S][Sp] += val
                remaining_states.extend(visited_states)
            P[S] = dict(P[S])
                
    return P, wSs

def system_matrix(G, P, W):
    # Construct Matrix
    states = {w:i for i,w in enumerate(sorted(W))}
    Q = zero_matrix(R, len(W))
    for S,row in P.items():
        for Sp,val in row.items():
            Q[states[S],states[Sp]] = -val
        Q[states[S], states[S]] += W[S]

    b = vector(-Q[1:-1,-1])
    Q = Q[1:-1,1:-1]
    
    return Q, b, states

def worker(G, rule, outfile):
    states_reducer = posibleStates(G)
    P, W = sparse_system_matrix(G, states_reducer, rule)
    Q,b,used_states = system_matrix(G, P, W)
    w = vector(R, [0]*len(b))
    for s, weight in W.items(): # Probably you could trust python and the order of W but... 
        if len(used_states)-1 > used_states[s] > 0:
            w[used_states[s]-1] = weight
            #For example vector([ W[S] for S,val in states.items() if 0 < val < len(states)-1])

    print(f"{rule.name()}_P = {P}", file=outfile)
    print(f"{rule.name()}_W = {W}", file=outfile)
    print(f"{rule.name()}_Q = {list(Q)}", file=outfile)
    print(f"{rule.name()}_b = {b}", file=outfile)
    print(f"{rule.name()}_used_states = {used_states}", file=outfile)
    print(f"{rule.name()}_w = {w}", file=outfile)

    #
    # Firstly the phi
    #
    DETERMINANT = Q.determinant()
    print(f"{rule.name()}_det = {DETERMINANT}", file=outfile)
    
    LHS = rule.row_phi(Q.ncols())
    values = rule.vars_and_vales(len(LHS))
    phis = [ Q.subs(s).change_ring(QQ).solve_right(b.subs(s).change_ring(QQ)) for s in values ]
    print(f"{rule.name()}_Phi_used_values = {values}", file=outfile)
    print(f"{rule.name()}_Phi_computed = {phis}", file=outfile)

    # Now I have to make the functions for each state with one single mutant
    PhiNum = {}
    for S,idx in used_states.items():
        if sum(S) == 1:
            V = matrix(QQ, [[v.subs(s) for v in LHS] for s in values])
            v = vector(QQ, [DETERMINANT.subs(s) * fs[idx-1] for s,fs in zip(values, phis)])

            assert V.rank() == V.ncols(), "I'm puzzled"
            
            PhiNum[S] = rule.recover_phinum(V.solve_right(v))
    print(f"{rule.name()}_PhiNum = {PhiNum}", file=outfile)

    # Mean value
    meanPhiNum = sum(PhiNum[S] for S in [ states_reducer[ 
                                    (0,) * i +
                                    (1,) + 
                                    (0,) * (G.order()-i-1)
                                   ] for i in range(G.order())]) / G.order()
    print(f"{rule.name()}_mean_phi = {(meanPhiNum/DETERMINANT)}", file=outfile)

    #
    # Unconditional Time
    #
    LHS = rule.row_unconditional_time(Q.ncols())
    values = rule.vars_and_vales(len(LHS))
    ucTimes = [ Q.subs(s).change_ring(QQ).solve_right(w.subs(s).change_ring(QQ)) for s in values ]
    print(f"{rule.name()}_UT_used_values = {values}", file=outfile)
    print(f"{rule.name()}_UT_computed = {ucTimes}", file=outfile)

    # Now I have to make the functions for each state with one single mutant
    Ts = {}
    for S,idx in used_states.items():
        if sum(S) == 1:
            V = matrix(QQ, [[v.subs(s) for v in LHS] for s,ts in zip(values, ucTimes)])
            v = vector(QQ, [DETERMINANT.subs(s) * ts[idx-1] for s,ts in zip(values, ucTimes)])

            assert V.rank() == V.ncols(), "I'm puzzled"
            
            Ts[S] = rule.recover_unconditional_timenum(V.solve_right(v))
    
    print(f"{rule.name()}_unconditional_times_num = {Ts}", file=outfile)

    # Mean value
    T = sum(Ts[S] for S in [ states_reducer[ 
                                    (0,) * i +
                                    (1,) + 
                                    (0,) * (G.order()-i-1)
                                   ] for i in range(G.order())]) / G.order()
    T /= DETERMINANT
    print(f"{rule.name()}_unconditional_mean_time_from1 = {T}", file=outfile)

    #
    # Conditional Time
    #
    LHS = rule.row_conditional_time(Q.ncols())
    values = rule.vars_and_vales(len(LHS))
    cTimes = []
    for s in values:
        _Q = Q.subs(s).change_ring(QQ)
        _b = b.subs(s).change_ring(QQ)
        _phi = _Q.solve_right(_b)

        _w = w.subs(s).change_ring(QQ)
        _w = vector(QQ, [x*y for x,y in zip(_phi,_w)])
        for i in range(_Q.ncols()):
            _Q.rescale_col(i, _phi[i])

        cTimes.append(_Q.solve_right(_w))
    print(f"{rule.name()}_CT_used_values = {values}", file=outfile)
    print(f"{rule.name()}_CT_computed = {cTimes}", file=outfile)

    # Now I have to make the functions for each state with one single mutant
    Ts = {}
    for S,idx in used_states.items():
        if sum(S) == 1:
            V = matrix(QQ, [[v.subs(s) for v in LHS] for s,ts in zip(values, cTimes)])            
            v = vector(QQ, [ DETERMINANT.subs(s) * PhiNum[S].subs(s) * ts[idx-1] for s,ts in zip(values, cTimes)])
            assert V.rank() == V.ncols(), "I'm puzzled"
            Ts[S] = (rule.recover_conditional_timenum(V.solve_right(v)) / PhiNum[S] / DETERMINANT)#.factor()

    print(f"{rule.name()}_conditional_times = {Ts}", file=outfile)

    # Mean value
    T = sum(Ts[S] for S in [ states_reducer[ 
                                    (0,) * i +
                                    (1,) + 
                                    (0,) * (G.order()-i-1)
                                   ] for i in range(G.order())]) / G.order()
    #T = T.factor()
    print(f"{rule.name()}_conditional_mean_time_from1 = {T}", file=outfile)


def compute_all(name, G):
    with open(f"{name}.sage", "wt") as outfile:
        print(f"G = {G.edges(labels=false, sort=True)}", file=outfile)

        for rule in [MoranRule, BernoulliRule]:
            worker(G, rule, outfile)


if os.path.isfile(f"{sys.argv[-1]}.sage"):
    quit()

for i,G in enumerate(G for G in graphs(6) if G.is_connected()):
    if i == int(sys.argv[-1]):
        break

compute_all(i, G)

