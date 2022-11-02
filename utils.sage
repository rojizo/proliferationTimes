def pc(f):
    a = 0
    b = 1
    sa = sgn(f(p=a))
    sb = sgn(f(p=b))
    assert(sa != sb)
    
    while b-a > 1e-18:
        c = (a+b)/2
        sc = sgn(f(p=c))
        if sc == sb:
            b = c
        else:
            a = c
    
    return (b+a) / 2