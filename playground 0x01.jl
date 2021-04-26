using Gtk, Images

# Matrix of cells represents CA status
# ADN = 512 * 3x3 Cell Matrix  ( 512 = 9^2 )

# initialize a 3x4 matrix to zeroes : 
# ca_matrix = zeros(Int32,height,width)

@enum CellDawShape SQUARE TRIANGLE CIRCLE

gtkCanvas = @GtkCanvas()

# call back for mouse events
gtkCanvas.mouse.button1press = @guarded (widget, event) -> begin
    ctx = getgc(widget)
    set_source_rgb(ctx, 0, 1, 0)
    x = event.x
    y = event.y

    arc(ctx, x, y, 5, 0, 2pi)
    rectangle(ctx, x - 15, y - 15, 30, 30)
    stroke(ctx)
    reveal(widget)
end

@guarded draw(gtkCanvas) do widget
    # Called by the main loop at specific frequency
    ctx = getgc(gtkCanvas)
    h = height(gtkCanvas)
    w = width(gtkCanvas)
    
    grid_size = min(size(ca.matrix)[1], size(ca.matrix)[2])
    
    clearColor = RGB(0.22, 0.23, 0.29)
    set_source_rgb(ctx, clearColor.r, clearColor.g, clearColor.b) # 56/255, 60/255, 74/255) - - - ---
    rectangle(ctx, 0, 0, w, h)
    fill(ctx)

    draw_grid(gtkCanvas, 5, 5)
    stroke(ctx)

    draw_ca(ctx, h, w)
    fill(ctx)
end

function draw_grid(canvas, grid_width, grid_height)
    ctx = getgc(canvas)
    h_canvas = height(canvas)
    w_canvas = width(canvas)
    w_cell = round(w_canvas / grid_width)
    h_cell = round(h_canvas / grid_height)
    cell_size = min(w_cell, h_cell)
    w_grid = cell_size * grid_width
    h_grid = cell_size * grid_height

    set_source_rgb(ctx, 0, 0, 0);
    set_line_width(ctx, 0.5);

    for x in 0:cell_size:w_grid
        move_to(ctx, x, 0)
        line_to(ctx, x, h_grid)
    end

    set_source_rgb(ctx, 0.23, 0.25, 0.29)
    for y  in 0:cell_size:h_grid
        move_to(ctx, 0, y)
        line_to(ctx, h_grid, y)
    end
    stroke(ctx)
end

function draw_ca(ctx, h_canvas, w_canvas)
    # called within @guarded draw(gtkCanvas) above
    matrix_h, matrix_w = size(ca.matrix)
    w_cell = round(w_canvas / matrix_w)
    h_cell = round(h_canvas / matrix_h)
    zeros_color = RGB(0.1, 0.11, 0.12)
    ones_color = RGB(0.6, 0.32, 0.32)
    for i in 0:matrix_h-1, j in 0:matrix_w-1
        value = ca.matrix[i + 1, j + 1]
        color = value == 1 ? ones_color : zeros_color
        set_source_rgb(ctx, color.r, color.g, color.b)
        rectangle(ctx, i * w_cell,  j * h_cell, w_cell - 1, h_cell - 1)
        fill(ctx)
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

win = GtkWindow(gtkCanvas, "CA", 1000, 1000)
show(gtkCanvas)

# cd = Condition()
# endit(ww) = notify(cd)                  
# signal_connect(endit, win, :destroy)
# showall(win)
# wait(cd)

mutable struct CellularAutomata
    matrix
end

function gol_number_of_adjacent_cells(i, j, previous_state_matrix)
    h,w = size(previous_state_matrix)
    
    empty_row = reshape( [ 0 for i = 1:w ] , (1,w) )
    empty_col = [ 0 for i = 1:h+2]

    tmp = [ empty_row ; previous_state_matrix ; empty_row ]
    tmp = [ empty_col  tmp  empty_col] 

    sub = tmp[i:i+2,j:j+2]
    sub[2,2] = 0 # don't count the center cell
    sum(sub)
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
    #ca.matrix = [ rand([0,1]) for i = 1:h, j = 1:w ]
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

target_frequency = 5

# init ca
s = 50
w, h = s, s
matrix = [ rand([0,1]) for i = 1:h, j = 1:w ]
ca = CellularAutomata(matrix)

# Main loop
while true
    t = time()
    tick_ca!(ca)
    draw(gtkCanvas)
    
    draw_time = time() - t
    time_to_sleep = 1 / target_frequency - draw_time
    if time_to_sleep > 0
        sleep(1 / target_frequency - draw_time)
    end
    #println("- draw time : $(round(draw_time, digits=9)) ")
    #println(ca)
    
    #println("target tick frequency : $target_frequency")
    actual_frequency = 1/(time()-t)
    println("actual tick frequency : $actual_frequency")
end
