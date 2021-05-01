using GLMakie
using Profile, BenchmarkTools

println("""=========================================================================================


                                ███▄ ▄███▓ ▄▄▄       ██▓ ███▄     █ 
                                ▓██▒▀█▀ ██▒▒████▄    ▓██▒ ██ ▀█   █ 
                                ▓██    ▓██░▒██  ▀█▄  ▒██▒▓██  ▀█ ██▒
                                ▒██    ▒██ ░██▄▄▄▄██ ░██░▓██▒  ▐▌██▒
                                ▒██▒   ░██▒ ▓█   ▓██▒░██░▒██░   ▓██░
                                ░ ▒░   ░  ░ ▒▒   ▓▒█░░▓  ░ ▒░   ▒ ▒ 
                                ░  ░      ░  ▒   ▒▒ ░ ▒ ░░ ░░   ░ ▒░
                                ░      ░     ░   ▒    ▒ ░   ░   ░ ░ 
                                    ░         ░  ░ ░           ░ 
                                  
===============================================================================================""")

time = Node(0.0)

xs = LinRange(0, 7, 40)

ys_1 = @lift(sin.(xs .- $time))
ys_2 = @lift(cos.(xs .- $time) .+ 3)

figure, _ = lines(xs, ys_1, color = :blue, linewidth = 4)
scatter!(xs, ys_2, color = :red, markersize = 15)
figure
# timestamps = 0:1/30:2

# record(figure, "time_animation.mp4", timestamps; framerate = 30) do t
#     time[] = t
# end