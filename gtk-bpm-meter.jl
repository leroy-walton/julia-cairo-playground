using Gtk

win = GtkWindow("BPM meter",100,50)
b1 = GtkButton("Tick")
hbox1 = GtkButtonBox(:h)
push!(hbox1, b1)
vbox = GtkBox(:v)
label0 = GtkLabel("BPM Meter")
label = GtkLabel("")
GAccessor.text(label,"0.")
push!(vbox, label0)
push!(vbox, label)
push!(vbox, hbox1)
push!(win, vbox)

text = "default text"
global t1 = 999999

function calculate_bpm()    
    t2 = time()
    bpm = 60 / (t2-t1)
    global t1 = t2
    bpm = round(bpm, digits=2)
    return string(bpm)
end

function button_clicked_callback(widget)
    if widget == b1
       	global text = calculate_bpm()
        GAccessor.text(label, text)
    end
end

id1 = signal_connect(button_clicked_callback, b1, "clicked")

c = Condition()
endit(w) = notify(c)
signal_connect(endit, win, :destroy)
showall(win)
wait(c)
