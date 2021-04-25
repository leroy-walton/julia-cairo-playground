using Gtk

c = @GtkCanvas()
win = GtkWindow(c, "Canvas")
@guarded draw(c) do widget
    ctx = getgc(c)
    h = height(c)
    w = width(c)
    
    set_source_rgb(ctx, 1, 0.3, 0.3)
    rectangle(ctx, 0, 0, w, h/2)
    fill(ctx)

end
show(c)

