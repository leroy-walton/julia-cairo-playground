using CSFML.LibCSFML
using ModernGL
using Profile, BenchmarkTools

mutable struct CellularAutomata
    matrix
end

function gol_number_of_adjacent_cells(i, j, matrix)
    # faster implementation :

    #   memory estimate:  0 bytes
    #   allocs estimate:  0
    #   --------------
    #   minimum time:     34.048 ns (0.00% GC)
    #   median time:      35.196 ns (0.00% GC)
    #   mean time:        35.230 ns (0.00% GC)
    #   maximum time:     101.239 ns (0.00% GC)
    #   --------------
    #   samples:          10000
    #   evals/sample:     993

    h, w = size(matrix)

    sum = 0
    if i == 1
        if j == 1
            #  __..
            # |0x
            # |xx

            sum = matrix[ 2, 1 ] + matrix[ 1, 2 ] + matrix[ 2, 2 ]
        elseif j == w
            #         ..__
            #           xo|
            #           xx|

            sum = matrix[ i+1, j ] + matrix[ i,j-1 ] + matrix[ i+1, j-1 ]
        else
            #   ..___..
            #     xox
            #     xxx

            sum = matrix[ i+1, j-1 ] + matrix[ i+1, j ] + matrix[ i+1, j+1 ] + 
                        matrix[ i, j-1 ] + matrix[ i, j+1 ]
        end
    elseif i == h
        if j == 1
            # :
            # |xx
            # |ox
            #  --

            sum = matrix[ i-1, j ] + matrix[ i-1, j+1 ] + matrix[ i, j+1 ]
        elseif j == w
            #               :
            #             xx|
            #             xo|
            #             --

            sum = matrix[ i, j-1 ] + matrix[ i-1, j ] + matrix[ i-1, j-1 ]
        else
            #
            #      xxx 
            #      xox
            #    ..---..

            sum = matrix[ i-1, j-1 ] + matrix[ i-1, j ] + matrix[ i-1, j+1 ] + 
                matrix[ i, j-1 ] + matrix[ i, j+1 ] 
        end
    else # 1 < i < h
        if j == 1
            #  :
            #  |xx
            #  |ox
            #  |xx
            #  :

            sum = matrix[ i-1, j+1 ] + matrix[ i, j+1 ] + matrix[ i+1, j+1] +
                 matrix[ i-1, j ] + matrix[ i+1, j ]
        elseif j == w
            #          :
            #        xx|
            #        xo|
            #        xx|
            #          :

            sum = matrix[ i-1, j-1 ] + matrix[ i, j-1 ] + matrix[ i+1, j-1 ] + 
                matrix[ i-1, j ] + matrix[ i+1, j ]
        else
            #     xxx
            #     xox
            #     xxx

            sum = matrix[ i-1, j-1 ] + matrix[ i-1, j ] + matrix[ i-1, j+1 ] + 
                  matrix[ i,   j-1 ]                    + matrix[ i,   j+1 ] + 
                  matrix[ i+1, j-1 ] + matrix[ i+1, j ] + matrix[ i+1, j+1 ]
        end
    end
    sum
end

# GOL rules
function gol_compute_next_state(i, j, previous_state_matrix)
	adjacent_live_cell_count = gol_number_of_adjacent_cells(i, j, previous_state_matrix)
    previous_state = previous_state_matrix[i,j]
    next_state = 0
    if previous_state == 1
        if adjacent_live_cell_count < 2
            next_state = 0
        elseif adjacent_live_cell_count <= 3
            next_state = 1
        elseif adjacent_live_cell_count > 3
            next_state = 0
        end
    elseif previous_state == 0
        if adjacent_live_cell_count == 3
            next_state = 1
        else
            next_state = 0
        end
    end
    next_state
end

function tick_ca!(ca::CellularAutomata)
    h, w = size(ca.matrix)
    next_matrix = similar(ca.matrix)
    for i=1:w, j=1:h
        next_matrix[i,j] = gol_compute_next_state(i, j, ca.matrix)
    end
    ca.matrix = next_matrix
end

function tick_ca!(ca::CellularAutomata, steps)
    for _ = 1:steps
        tick_ca!(ca)
    end
end

function draw_scene(window)
    size = sfRenderWindow_getSize(window)

    h = size.x
    w = size.y
    
    draw_ca(window)
end

function draw_ca(window)
    matrix_h, matrix_w = size(ca.matrix)
    w_cell = w_canvas / matrix_w
    h_cell = h_canvas / matrix_h

    for i in 0:matrix_h-1, j in 0:matrix_w-1
        value = ca.matrix[i + 1, j + 1]
        if value == 1
            #rectangle(ctx, i * w_cell,  j * h_cell, w_cell - 1, h_cell - 1)    

        end
    end
end

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


# init window
mode = sfVideoMode(700, 720, 32)
window = sfRenderWindow_create(mode, "SFML window", sfResize | sfClose, C_NULL)
@assert window != C_NULL
sfWindow_setVerticalSyncEnabled(window,true)
sfWindow_setActive(window, sfTrue)

# init font
font = sfFont_createFromFile(joinpath("/julia/playgrounds/resources/NotoSans-Black.ttf"))
@assert font != C_NULL

# init ca
target_frequency =10
s = 600
w, h = s, s
matrix = [ rand([0,1]) for i = 1:h, j = 1:w ]
ca = CellularAutomata(matrix)

# init clock
clock = sfClock_create()
# Let's express time in seconds.
function get_time(clock ::Ptr{Nothing})
    sfTime_asSeconds(sfClock_getElapsedTime(clock))
end
function restart(clock ::Ptr{Nothing})
     sfTime_asSeconds(sfClock_restart(clock))
end

event_ref = Ref{sfEvent}()
target_frequency = 24.0
t0 = 9999999
running = true
while (running)

    while Bool(sfRenderWindow_isOpen(window)) && running
        frame_timestamp = get_time(clock)
        frame_time = frame_timestamp - t0
        t0 = get_time(clock)
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
                    println("Quiting application.")
                end
            end
        end
        time_event_processing = round(get_time(clock) - t0, digits=9)
        #println("Event processing took $time_event_processing seconds.")
        
        # Render scene
        sfRenderWindow_clear(window, sfColor_fromRGBA(24,20,18,255))
        
        square = sfRectangleShape_create()
        sfRectangleShape_setSize(square, sfVector2f(50,50) )
        t_warp = frame_timestamp + sin(frame_timestamp*2.2)*1.5
        sfRectangleShape_setPosition(square, sfVector2f(80+cos(t_warp*2.3)*20, 240+sin(t_warp*1.8)*200))
        sfRectangleShape_setFillColor(square,sfColor_fromRGBA(255,155,105,255) )

        sfRenderWindow_drawRectangleShape(window, square, C_NULL) 

        time_render = round(get_time(clock) - time_event_processing - t0, digits=9)
        
        sf_text = sfText_create()
        sfText_setPosition(sf_text, sfVector2f(4,700))
        sfText_setString(sf_text, "frame render time : $time_render seconds.")
        sfText_setFont(sf_text, font)
        sfText_setCharacterSize(sf_text, 14)
        sfRenderWindow_drawText(window, sf_text, C_NULL)

        sf_text2 = sfText_create()
        sfText_setPosition(sf_text2, sfVector2f(4,680))
        sfText_setString(sf_text2, "fps : $actual_frequency")
        sfText_setFont(sf_text2, font)
        sfText_setCharacterSize(sf_text2, 14)
        sfRenderWindow_drawText(window, sf_text2, C_NULL)

        sfRenderWindow_display(window)
        time_to_sleep = 1 / target_frequency - time_render - time_event_processing
        
        if time_to_sleep > 0.001
            sleep(time_to_sleep-0.005)
        end
    end

end

#sfText_destroy(text)
sfFont_destroy(font)
#sfSprite_destroy(sprite)
#sfTexture_destroy(texture)
sfRenderWindow_destroy(window)
