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
    
    grid_size = 5
    
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
    w_cell = round(w_canvas / 5)
    h_cell = round(h_canvas / 5)
    zeros_color = RGB(0.1, 0.11, 0.12)
    ones_color = RGB(0.6, 0.32, 0.32)
    for i in 0:4, j in 0:4
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

function tick_ca!(ca::CellularAutomata)
    ca.matrix = [ rand([0,1]) for i = 1:5, j = 1:5 ]
end

function tick_ca!(ca::CellularAutomata, steps)
        for _ = 1:steps
        tick_ca!(ca)
    end
end

target_speed = 2.1  # speed in hz

# init ca
matrix_5x5 = [ rand([0,1]) for i = 1:5, j = 1:5 ]
ca = CellularAutomata(matrix_5x5)

# Main loop
while true
    t = time()
    tick_ca!(ca)
    draw(gtkCanvas)
    
    draw_time = time() - t
    
    sleep(1 / target_speed - draw_time)
    println(round(draw_time, digits=9))
    println(ca)
end
