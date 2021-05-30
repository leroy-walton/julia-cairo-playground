using CSFML.LibCSFML

using ModernGL
include("ModernGL_utils.jl")


#using GeometryTypes
mode = sfVideoMode(700, 720, 32)

# settings = SF::ContextSettings.new(
#   depth: 24, stencil: 8, antialiasing: 4,
#   major: 3, minor: 0
# )

window = sfRenderWindow_create(mode, "SFML window", sfResize | sfClose, C_NULL)
@assert window != C_NULL
sfWindow_setVerticalSyncEnabled(window,true)
sfWindow_setActive(window, sfTrue)

font = sfFont_createFromFile(joinpath("/julia/playgrounds/resources/NotoSans-Black.ttf"))
@assert font != C_NULL

text = sfText_create()
sfText_setString(text, "The quick brown fox jumps over the lazy dog.")
sfText_setPosition(text, sfVector2f(100,5))
sfText_setFont(text, font)
sfText_setCharacterSize(text, 20)

data = GLfloat[
    0.0, 0.5,
    0.5, -0.5,
    -0.5,-0.5
]

# load resources, initialize the OpenGL states,
# vbo
createcontextinfo()
vao = glGenVertexArray()
glBindVertexArray(vao)
vbo = glGenBuffer()
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW)

# shader
const vsh = """
    $(get_glsl_version_string())
    //layout(location = 0) in vec3 v_position;
    //layout(location = 1) in vec3 v_colour;

    in vec3 position;
    in vec3 color;
    out vec3 gl_Color;
    void main() {
        gl_Color = color;
        gl_Position = vec4(position, 1.0);
    }
    """
const fsh = """
    $(get_glsl_version_string())
    out vec4 outColor;
    void main() {
        outColor = vec4(1.0, 1.0, 1.0, 1.0);
    }
    """
vertexShader = createShader(vsh, GL_VERTEX_SHADER)
fragmentShader = createShader(fsh, GL_FRAGMENT_SHADER)
program = createShaderProgram(vertexShader, fragmentShader)
glUseProgram(program)
positionAttribute = glGetAttribLocation(program, "position");
glEnableVertexAttribArray(positionAttribute)
glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, false, 0, C_NULL)

# sfEvtMouseButtonPressed

###############

points = [
   0.0,  0.5,  0.0,
   0.5, -0.5,  0.0,
  -0.5, -0.5,  0.0
]
colors = [
    1,0,0,
    0,1,0,
    0,0,1
]
points_vbo = glGenBuffer()
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glBufferData(GL_ARRAY_BUFFER, 9 * sizeof(Float64), points, GL_STATIC_DRAW)
colours_vbo = glGenBuffer()
glBindBuffer(GL_ARRAY_BUFFER, colours_vbo)
glBufferData(GL_ARRAY_BUFFER, 9 * sizeof(Float64), colors, GL_STATIC_DRAW)
vao2 = glGenVertexArray()
glBindVertexArray(vao2)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, colours_vbo)
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0);
glEnableVertexAttribArray(1);


event_ref = Ref{sfEvent}()
clock = sfClock_create()
# Let's express time in seconds.
function get_time(clock ::Ptr{Nothing})
    sfTime_asSeconds(sfClock_getElapsedTime(clock))
end
function restart(clock ::Ptr{Nothing})
     sfTime_asSeconds(sfClock_restart(clock))
end

target_frequency = 24.0
running = true
t0 = 9999999
while (running)

    while Bool(sfRenderWindow_isOpen(window)) && running
        frame_timestamp = get_time(clock)
        frame_time = frame_timestamp - t0
        t0 = frame_timestamp
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
        
     
        sfRenderWindow_popGLStates(window)

    	glClearColor(
            0.5 * (0.5 + sin(get_time(clock) * 5)),
            0.05,
            0.07,
            1.0
            )

    	glClear(GL_COLOR_BUFFER_BIT)

        glBindVertexArray(vao)
        glDrawArrays(GL_TRIANGLES, 0, 3)

        sfRenderWindow_pushGLStates(window)
        sfRenderWindow_resetGLStates(window)

        sfRenderWindow_drawText(window, text, C_NULL)

        # --sfRenderStates
        # state.shader = shader;
        # state.blendMode = sfBlendAlpha;
        # state.transform = sfTransform_Identity;
        # state.texture = NULL;
        # struct sfRenderStates
        #     blendMode::sfBlendMode
        #     transform::sfTransform
        #     texture::Ptr{sfTexture}
        #     shader::Ptr{sfShader}
        # end

        # --shader
        # string frag = r"void main() { gl_FragColor = vec4(1,0,0,1); }";
        # sfShader* shader = sfShader_createFromMemory(null, frag);
        # sf::Shader shader; shader.loadFromMemory(frag, sf::Shader::Fragment);

        time_render = round(get_time(clock) - time_event_processing - t0, digits=9)

        sf_text = sfText_create()
        sfText_setPosition(sf_text, sfVector2f(4,700))
        sfText_setString(sf_text, "frame render time : $time_render seconds.")
        sfText_setFont(sf_text, font)
        sfText_setCharacterSize(sf_text, 14)
        sfRenderWindow_drawText(window, sf_text, C_NULL)

        sf_text2 = sfText_create()
        sfText_setPosition(sf_text2, sfVector2f(0.,0.))
        sfText_setString(sf_text2, "fps : $actual_frequency")
        sfText_setFont(sf_text2, font)
        sfText_setCharacterSize(sf_text2, 14)
        sfText_setColor(sf_text2, sfColor(240,150,140,255))
        sfRenderWindow_drawText(window, sf_text2, C_NULL)
        sfRenderWindow_popGLStates(window)
        sfRenderWindow_display(window)
        time_to_sleep = 1 / target_frequency - time_render - time_event_processing
        
        if time_to_sleep > 0.005
            sleep(time_to_sleep-0.005)
        end
    end

end

sfText_destroy(text)
sfFont_destroy(font)
sfRenderWindow_destroy(window)