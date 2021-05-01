using CSFML.LibCSFML

t1 = sfMicroseconds(1000000)
t2 = sfMilliseconds(1000)
t3 = sfSeconds(1)

clock = sfClock_create()
println("Clock initialized.")
println("sleep()")
sfSleep(t1)

seconds_elapsed = sfTime_asSeconds(sfClock_getElapsedTime(clock))
println("elapsed time : $seconds_elapsed sec.")

function get_time(clock ::Ptr{Nothing})
   sfTime_asSeconds(sfClock_getElapsedTime(clock))
end

function restart(clock ::Ptr{Nothing})
    sfTime_asSeconds(sfClock_restart(clock))
end

t = get_time(clock)
println("reseting clock at $t seconds.")
println(restart(clock))

println("sleep 3 seconds.")
sleep(3)
t = get_time(clock)
println("$t seconds have elapsed.")

