using Base: Int32
using CSFML.LibCSFML
using ModernGL
#using GeometryTypes
include("ModernGL_utils.jl")

###Init

mode = sfVideoMode(700, 720, 32)
# settings = SF::ContextSettings.new(
#   depth: 24, stencil: 8, antialiasing: 4,
#   major: 3, minor: 0
# )
window = sfRenderWindow_create(mode, "SFML window", sfResize | sfClose, C_NULL)
@assert window != C_NULL
sfWindow_setVerticalSyncEnabled(window,true)
sfWindow_setActive(window, sfTrue)
println(createcontextinfo()) # used by ModernGL_utils;
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)
glClearColor(0.4 ,0.2, 0.3, 1.0)

### shaders

vsh = """
    $(get_glsl_version_string())
    //layout(location = 0) in vec3 v_position;
    //layout(location = 1) in vec3 v_color;

    in vec3 v_position;
    in vec3 v_color;
    out vec3 initial_Color;
    void main() {
        initial_Color = v_color;
        gl_Position = vec4(v_position, 1.0);
    }
    """

fsh = """
    $(get_glsl_version_string())
    in vec3 initial_Color;
    out vec4 outColor;
    void main() {
        outColor = vec4(5.0, 2.0, 3.0, 1.0);
        //outColor = vec4(frag_colour, 1.0 );
    }
    """

vertexShader = createShader(vsh, GL_VERTEX_SHADER)
fragmentShader = createShader(fsh, GL_FRAGMENT_SHADER)

function bindAttrib(shader_program) 
    glBindAttribLocation(shader_program, 0, "v_position");
    glBindAttribLocation(shader_program, 1, "v_color");
end

program = createShaderProgram( bindAttrib, vertexShader, fragmentShader)
glUseProgram(program)

print("shader ---> ")
glCheckError()

#value = Int32(-1)
#glGetProgramiv(program, GL_ATTACHED_SHADERS, value)
#println("GL_ATTACHED_SHADERS = $value")


### vertex, colors and buffers

points = GLfloat[
   0.0,  0.5,  0.0,
   0.5, -0.5,  0.0,
  -0.5, -0.5,  0.0
]

colors = GLfloat[
    1.0, 0.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 0.0, 1.0
]

points_vbo = glGenBuffer()
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)


colors_vbo = glGenBuffer()
glBindBuffer(GL_ARRAY_BUFFER, colors_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW)

vao = glGenVertexArray()
glBindVertexArray(vao)
glEnableVertexAttribArray(0);
glEnableVertexAttribArray(1);

glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)

glBindBuffer(GL_ARRAY_BUFFER, colors_vbo)
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
print("vertexArray ---> ")
glCheckError()


glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
positionAttribute = glGetAttribLocation(program, "v_position");
print("VertexAttribPointer ---> ")
glCheckError()
println("positionAttribute : $positionAttribute")
glEnableVertexAttribArray(positionAttribute)
println("enableVertArr ---> ")
glCheckError()
glVertexAttribPointer(positionAttribute, 3, GL_FLOAT, false, 0, C_NULL)
println("VertexAttribPointer ---> ")
glCheckError()

glBindBuffer(GL_ARRAY_BUFFER, colors_vbo)
colorAttribute = glGetAttribLocation(program, "v_color");
println(" glGetAttribLocation ---> ")
glCheckError()
println("colorAttribute : $colorAttribute")



#glEnableVertexAttribArray(colorAttribute)

#glEnableVertexAttribArray(1)
#glVertexAttribPointer(1, 3, GL_FLOAT, false, 0, C_NULL)

event_ref = Ref{sfEvent}()
clock = sfClock_create()
# Let's express time in seconds.
function get_time(clock::Ptr{sfClock})
    sfTime_asSeconds(sfClock_getElapsedTime(clock))
end
function restart(clock::Ptr{sfClock})
     sfTime_asSeconds(sfClock_restart(clock))
end

target_frequency = 24.0
running = true
t0 = 9999999
while (running)

    while Bool(sfRenderWindow_isOpen(window)) && running
        frame_timestamp = get_time(clock)
        frame_time = frame_timestamp - t0
        global t0 = frame_timestamp
        actual_frequency = 1 / frame_time
        
        # process events
        while Bool(sfRenderWindow_pollEvent(window, event_ref))
            # close window : exit
            event_ref[].type == sfEvtClosed && sfRenderWindow_close(window)
            event_ref[].type == sfEvtResized && println("Trigger sfEvtResized.")
            event_ref[].type == sfEvtLostFocus && println("Trigger sfEvtLostFocus.")
            event_ref[].type == sfEvtGainedFocus && println("Trigger sfEvtGainedFocus.")
            event_ref[].type == sfEvtTextEntered && println("Trigger sfEvtTextEntered: $(event_ref[].text.unicode)")
            event_ref[].type == sfEvtKeyPressed && println("Trigger sfEvtKeyPressed: $(event_ref[].key.code)")
            event_ref[].type == sfEvtKeyReleased && println("Trigger sfEvtKeyReleased: $(event_ref[].key.code)")
            event_ref[].type == sfEvtMouseWheelMoved && println("Trigger sfEvtMouseWheelMoved: $(event_ref[].mouseWheel.x), $(event_ref[].mouseWheel.y)")
            event_ref[].type == sfEvtMouseWheelScrolled && println("Trigger sfEvtMouseWheelScrolled: $(event_ref[].mouseWheelScroll.wheel)")
            event_ref[].type == sfEvtMouseButtonPressed && println("Trigger sfEvtMouseButtonPressed: $(event_ref[].mouseButton.button)")
            event_ref[].type == sfEvtMouseButtonReleased && println("Trigger sfEvtMouseButtonReleased: $(event_ref[].mouseButton.x), $(event_ref[].mouseButton.y)")
            event_ref[].type == sfEvtMouseMoved && println("Trigger sfEvtMouseMoved: $(event_ref[].mouseMove.x), $(event_ref[].mouseMove.y)")
            
            if event_ref[].type == sfEvtClosed
                global running = false
                println("Render window closed.")
            elseif event_ref[].type == sfEvtResized
                glViewport(9, 9, event_ref[].size.width, event_ref[].size.height)
                println("Viewport updated.")
            elseif event_ref[].type == sfEvtKeyPressed
                if event_ref[].key.code == sfKeyQ
                    global running = false
                    println("Quiting application.")
                end
            end
        end
        time_event_processing = round(get_time(clock) - t0, digits=9)
        #glPolygonMode(GL_FRONT, GL_LINE)
    	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        #glBindBuffer(GL_ARRAY_BUFFER, colors_vbo)
        glUseProgram(program)
        glBindVertexArray(vao)
        glDrawArrays(GL_TRIANGLES, 0 , 3)

        time_render = round(get_time(clock) - time_event_processing - t0, digits=9)

        #sfRenderWindow_pushGLStates(window)
        #sfRenderWindow_resetGLStates(window)
        #sfRenderWindow_popGLStates(window)

        sfRenderWindow_display(window)
        time_to_sleep = 1 / target_frequency - time_render - time_event_processing

        if time_to_sleep > 0.005
            sleep(time_to_sleep-0.005)
        end
    end
end

sfRenderWindow_destroy(window)