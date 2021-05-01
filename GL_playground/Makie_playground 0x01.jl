using GLMakie

# Observable

x = Node(1.0)
y = Node(2.0)

z = @lift($x .+ $y)

f = Figure(resolution = (1000,600))

ax1 = f[1,1] = Axis(f,
    aspect = 1, targetlimits = BBox(-10,10,-10,10),
    title = "GLMakie & Observable test",
    titlegap = 28, titlesize=20,
    xautolimitmargin = (0,0), xgridwidth = 2, xticklabelsize=10,
    xticks = LinearTicks(20), xticksize = 18,
    yautolimitmargin = (0,0), ygridwidth = 2, yticklabelpad = 14,
    yticklabelsize=10, yticks = LinearTicks(20), yticksize=18
)

vlines!(ax1, [0], linewidth = 1)
hlines!(ax1, [0], linewidth = 1)

slope = Node(1.0)
intercept = Node(0.0)
x = -10:0.01:10
y = @lift($slope .* x .+ $intercept)
line1 = lines!(ax1, x, y, color= :red, linewidth = 2)

println("****")

xlims!(ax1, -10, 10)
ylims!(ax1, -10, 10)

println(f)
println("bleh")

f

# sleep(5)
# for i in 1:100
#     intercept[] = intercept[] + 0.02
#     sleep(0.2)
# end

