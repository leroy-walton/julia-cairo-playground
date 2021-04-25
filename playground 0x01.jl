using Gtk, Images

# Matrix of cells represents CA status
# ADN = 512 * 3x3 Cell Matrix  ( 512 = 9^2 )

@enum CellDawShape SQUARE TRIANGLE CIRCLE

function draw_grid(canvas, grid_width, grid_height )
    ctx = getgc(canvas)

    canvas_h = height(canvas)
    canvas_w = width(canvas)

    cell_width = round( canvas_w / grid_width )
    cell_height = round( canvas_h / grid_height )

    cell_size = min(cell_width,cell_height)

    set_source_rgb(ctx, 0, 0, 0);
    set_line_width(ctx, 0.5);

    for x in 0:cell_size:canvas_w
        move_to(ctx, x, 0)
        line_to(ctx, x, canvas_h)
    end
    for y  in 0:cell_size:canvas_h
        move_to(ctx,0,y)
        line_to(ctx,canvas_w,y)
    end

    stroke(ctx)
    #ca_matrix = Matrix(height,width)
end


gtkCanvas = @GtkCanvas()
win = GtkWindow(gtkCanvas, "Canvas")

# call back for mouse events
gtkCanvas.mouse.button1press = @guarded (widget, event) -> begin
    ctx = getgc(widget)
    set_source_rgb(ctx, 0, 1, 0)
    x = event.x
    y = event.y

    arc(ctx, x, y, 5, 0, 2pi)
    rectangle(ctx, x-15, y-15, 30, 30)
    stroke(ctx)
    reveal(widget)
end

@guarded draw(gtkCanvas) do widget
    ctx = getgc(gtkCanvas)
    h = height(gtkCanvas)
    w = width(gtkCanvas)

    grid_size = 5
 
    set_source_rgb(ctx, 0.23, 0.23, 0.21)
    rectangle(ctx, 0, 0, w, h/2)
    fill(ctx)

    draw_grid(gtkCanvas,5,5)
    fill(ctx)
    stroke(ctx)

end

show(gtkCanvas)
