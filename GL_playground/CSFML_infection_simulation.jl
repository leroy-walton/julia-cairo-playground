using CSFML.LibCSFML
using ColorTypes
using ModernGL

struct Coordinate
	x::Int64
	y::Int64
end

function make_tuple(c)
	(c.x, c.y)
end

function Base.:+(a::Coordinate, b::Coordinate)
	Coordinate(a.x+b.x,a.y+b.y)
end

possible_moves = [
	Coordinate( 1, 0), 
	Coordinate( 0, 1), 
 	Coordinate(-1, 0), 
 	Coordinate( 0,-1),
]

function collide_boundary(c::Coordinate, L::Number)
	cx = c.x
	cy = c.y
	
	if cx < -L
		cx = -L
	end
	if cy < -L
			cy = -L
	end
	if cx > L
		cx = L
	end
	if cy > L
		cy = L
	end
	Coordinate(cx,cy)
end

@enum InfectionStatus S I R

mutable struct Agent
	position::Coordinate
	status::InfectionStatus
	num_infected::Int64
end

function initialize(N::Number, L::Number)
	agents=[]
	for _ in 1:N
		c = Coordinate(rand(-L:L), rand(-L:L) )
		a = Agent(c,S::InfectionStatus,0)
		push!(agents,a)
	end

	agents[rand(1:N)].status = I::InfectionStatus
	return agents
end

function getColor(s::InfectionStatus) 
    color_I = RGB(0.4, 0.5, 1.0) 
    color_R = RGB(1.0, 0.4 ,0.4 )
    color_S = RGB(0.4, 1.0, 0.4)

    if s == S
        color_S
	elseif s == I
		color_I
	else
		color_R
    end
end

position(a::Agent) = a.position
getColor(a::Agent) = getColor(a.status)

abstract type AbstractInfection end

struct CollisionInfectionRecovery <: AbstractInfection
	p_infection::Float64
	p_recovery::Float64
end

function interact!(agent::Agent, source::Agent, infection::CollisionInfectionRecovery)
	if agent.position == source.position
		if source.status == I && agent.status == S
		# Chance of infection
			if rand() < infection.p_infection
				agent.status = I
				source.num_infected += 1
			end
		end
		if agent.position == source.position
			if agent.status == I
			# Chance of recovery
				if rand() < infection.p_recovery
					agent.status = R
				end
			end
		end
	end
end

function step!(agents::Vector, L::Number, infection::AbstractInfection)

	a = rand(agents)
	a.position = collide_boundary(a.position+rand(possible_moves), L)
	#interact
    for other in agents
		if other !== a
			interact!(a,other,infection)
		end
	end
	agents
end


#===================================================================================================

                        ▒█████        ██▓      ▒█████        ██▓      ▒█████       
                        ▒██▒  ██▒     ▓██▒     ▒██▒  ██▒     ▓██▒     ▒██▒  ██▒     
                        ▒██░  ██▒     ▒██▒     ▒██░  ██▒     ▒██▒     ▒██░  ██▒     
                        ▒██   ██░     ░██░     ▒██   ██░     ░██░     ▒██   ██░     
                    ██▓ ░ ████▓▒░ ██▓ ░██░ ██▓ ░ ████▓▒░ ██▓ ░██░ ██▓ ░ ████▓▒░ ██▓ 
                    ▒▓▒ ░ ▒░▒░▒░  ▒▓▒ ░▓   ▒▓▒ ░ ▒░▒░▒░  ▒▓▒ ░▓   ▒▓▒ ░ ▒░▒░▒░  ▒▓▒ 
                    ░▒    ░ ▒ ▒░  ░▒   ▒ ░ ░▒    ░ ▒ ▒░  ░▒   ▒ ░ ░▒    ░ ▒ ▒░  ░▒  
                    ░   ░ ░ ░ ▒   ░    ▒ ░ ░   ░ ░ ░ ▒   ░    ▒ ░ ░   ░ ░ ░ ▒   ░   
                    ░      ░ ░    ░   ░    ░      ░ ░    ░   ░    ░      ░ ░    ░  
                    ░             ░        ░             ░        ░             ░  
===================================================================================================#

# init simulation

number_of_agents = 50
L=40

agents = initialize(number_of_agents, L)
pandemic = CollisionInfectionRecovery( 0.3, 0.01 )

# init rendering engine

target_frequency = 20.0

mode = sfVideoMode(1000, 1000, 32)
window = sfRenderWindow_create(mode, "SFML window", sfResize | sfClose, C_NULL)
@assert window != C_NULL
sfWindow_setVerticalSyncEnabled(window,true)
sfWindow_setActive(window, sfTrue)

font = sfFont_createFromFile(joinpath("/julia/playgrounds/resources/NotoSans-Black.ttf"))
@assert font != C_NULL

clock = sfClock_create()

# express time in seconds.
function get_time(clock ::Ptr{Nothing})
    sfTime_asSeconds(sfClock_getElapsedTime(clock))
end
function restart(clock ::Ptr{Nothing})
     sfTime_asSeconds(sfClock_restart(clock))
end


function drawSquare(window, square, x, y, color::RGB)
        function f2i(f)
            round(f*255)
        end
        function to_sfColor(color::RGB)
            sfColor_fromRGB(f2i(color.r) ,f2i(color.g) , f2i(color.b) )
        end
        
        sfRectangleShape_setPosition(square, sfVector2f(x, y))        
        sfRectangleShape_setFillColor(square, to_sfColor(color) )

        sfRenderWindow_drawRectangleShape(window, square, C_NULL) 
end



# main loop

running = true
t0 = 0
event_ref = Ref{sfEvent}()
while (running)

    while Bool(sfRenderWindow_isOpen(window)) && running
        frame_timestamp = get_time(clock)
        frame_time = frame_timestamp - t0
        t0 = frame_timestamp
        actual_frequency = 1 / frame_time

        # process events
        while Bool(sfRenderWindow_pollEvent(window, event_ref))
            if event_ref[].type == sfEvtClosed
                sfRenderWindow_close(window)
                running = false
                println("Render window closed.")
            elseif event_ref[].type == sfEvtResized
                glViewport(9, 9, event_ref[].size.width, event_ref[].size.height)
                println("Viewport updated.")
            elseif event_ref[].type == sfEvtKeyPressed
                if event_ref[].key.code == sfKeyQ
                    running = false
                    println("Quitting application.")
                end
            end
        end
        time_event_processing = get_time(clock) - t0
        #println("Event processing took $time_event_processing seconds.")
        
        # Render scene

        sfRenderWindow_clear(window, sfColor_fromRGBA(24,20,18,255))
    
        s = 1000/ (2*L)
        square = sfRectangleShape_create()
        sfRectangleShape_setSize(square, sfVector2f(s,s) )
        sfRectangleShape_setFillColor(square,sfColor_fromRGBA(255,155,105,255) )

    
        for a in agents
            x = a.position.x * 20
            y = a.position.y * 20
            drawSquare(window, square, x, y, getColor(a) )
        end

        step!(agents, L, pandemic)

        time_render = get_time(clock) - time_event_processing - t0
        
        sf_text = sfText_create()
        sfText_setPosition(sf_text, sfVector2f(4,1000-20))
        sfText_setString(sf_text, "frame render time : $time_render seconds.")
        sfText_setFont(sf_text, font)
        sfText_setCharacterSize(sf_text, 14)
        sfRenderWindow_drawText(window, sf_text, C_NULL)

        sf_text2 = sfText_create()
        sfText_setPosition(sf_text2, sfVector2f(4,1000-40))
        sfText_setString(sf_text2, "fps : $actual_frequency")
        sfText_setFont(sf_text2, font)
        sfText_setCharacterSize(sf_text2, 14)
        sfRenderWindow_drawText(window, sf_text2, C_NULL)

        sfRenderWindow_display(window)
        sleep(0.002)
        time_to_sleep = 1 / target_frequency - time_render - time_event_processing
        if time_to_sleep > 0.005
            sleep(time_to_sleep-0.005)
        end
    end

end

sfFont_destroy(font)
sfRenderWindow_destroy(window)

