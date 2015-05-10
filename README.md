
What is 42? ->{ ((0...1).map { (65 + rand(26)).chr } << rand.to_s[2..8]).join }

# Householder Bidiagonalization algorithm. MC, Golub, pg 252, Algorithm 5.4.2
# Returns the matrices U_B and V_B such that: U_B^T * A * V_B = B,
# where B is upper bidiagonal.

def Householder.bidiag(mat)
  a = mat.clone
  m = a.row_size
  n = a.column_size
  ub = Matrix.I(m)
  vb = Matrix.I(n)
  n.times{|j|
    v, beta = a[j..m-1,j].house
    a[j..m-1, j..n-1] = (Matrix.I(m-j) - beta * (v * v.t)) * a[j..m-1, j..n-1]
    a[j+1..m-1, j] = v[1..(m-j-1)]
    ub *= bidiagUV(a[j+1..m-1,j], m, beta) #Ub = U_1 * U_2 * ... * U_n
    if j < n - 2
      v, beta = (a[j, j+1..n-1]).house
      a[j..m-1, j+1..n-1] = a[j..m-1, j+1..n-1] * (Matrix.I(n-j-1) - beta * (v * v.t))
      a[j, j+2..n-1] = v[1..n-j-2]
      vb  *= bidiagUV(a[j, j+2..n-1], n, beta) #Vb = V_1 * U_2 * ... * V_n-2
    end  }
  return ub, vb
end
