#=
	@author Wayne Chew

	Sodoku Solver using linear programming

	USAGE: julia solver.jl <filename>
	
	Solve the sodoku in filename.in and output it to filename.out
	
	Valid sample file in "sodoku.in"
	Infeasible sample file in "infeasible.in"

	Sample output "sodoku.out" and "infeasible.out"
=#

# Load arguments
if length(ARGS) != 1
	println("USAGE: julia solver.jl <filename>")
	quit()
end

# Read input file
filename = ARGS[1]
sodoku_input = []

try
	sodoku_input = readcsv(filename, Int64)
catch err
	info(err)
	quit()
end

# Check for valid input
num_rows, num_cols = size(sodoku_input)

if num_rows != 9 || num_cols != 9
	println("ERROR: Dimension of the input must be 9x9")
	quit()
end

for i in 1:num_rows
	for j in 1:num_cols
		if sodoku_input[i,j] < 0 || sodoku_input[i,j] > 9
			println("ERROR: Invalid sodoku input.")
			println("Cell is invalid at position (", i, ",", j, ") with a value of: ", sodoku_input[i,j])
			quit()
		end
	end
end

# Solver
using JuMP

m = Model()

@variable(m, x[1:9, 1:9, 1:9], Bin)

# Each cell can only have one number
@constraint(m, s1[i=1:9, j=1:9], sum(x[i,j,:]) == 1)

# Each number in a row is unique
@constraint(m, s2[i=1:9, j=1:9], sum(x[i,:,j]) == 1)

# Each number in a column is unique
@constraint(m, s3[i=1:9, j=1:9], sum(x[:,i,j]) == 1)

# Each number in a sodoku box is unique
@constraint(m, s4[i=0:2, j=0:2, k=1:9], sum(x[i*3+1:i*3+3, j*3+1:j*3+3, k]) == 1)

# Add input constraint
@constraintref s5[1:9, 1:9]
for i in 1:9
	for j in 1:9
		if sodoku_input[i,j] != 0
			s5[i,j] = @constraint(m, x[i,j,sodoku_input[i,j]] == 1)
		end
	end
end
	
@objective(m, Min, sum(x))

status = solve(m)

output_filename = string(join((split(filename, "."))[1:end-1]), ".out")

if status != :Optimal
	println("Sodoku <", filename, "> is not feasible")
	
	open(output_filename, "w") do f
		write(f, "Not Feasible")
	end

	quit()
end

# Convert results to output array
result = convert(Array{Int64,3}, getvalue(x))
sodoku_output = sodoku_input

nums = 1:9

for i in 1:num_rows
	for j in 1:num_cols
		sodoku_output[i,j] = (result[i,j,:]' * nums)[1]
	end
end

writecsv(output_filename, sodoku_output)