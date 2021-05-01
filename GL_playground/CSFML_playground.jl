using CSFML
using CSFML.LibCSFML

using ModernGL

mode = sfVideoMode(700, 720, 32)


# sf::Style::None	Aucune décoration (utile pour les splash screens, par exemple) ; ce style ne peut pas être combiné avec les autres
# sf::Style::Titlebar	La fenêtre possède une barre de titre
# sf::Style::Resize	La fenêtre peut être redimensionnée et possède un bouton de maximisation
# sf::Style::Close	La fenêtre possède une bouton de fermeture
# sf::Style::Fullscreen	La fenêtre est créée en mode plein écran; ce style ne peut pas être combiné avec les autres, et requiert un mode vidéo valide
# sf::Style::Default	Le style par défaut, qui est un raccourci pour Titlebar | Resize | Close
# https://www.sfml-dev.org/tutorials/2.5/window-window-fr.php

window = sfRenderWindow_create(mode, "SFML window", sfResize | sfClose, C_NULL)
@assert window != C_NULL

texture = sfTexture_createFromFile(joinpath("/julia/resources/ghost.jpg"), C_NULL)
@assert texture != C_NULL

sprite = sfSprite_create()
sfSprite_setTexture(sprite, texture, sfTrue)

font = sfFont_createFromFile(joinpath("/julia/resources/NotoSans-Black.ttf"))
@assert font != C_NULL

text = sfText_create()
sfText_setString(text, ".oOo. How does this looks ?")
sfText_setFont(text, font)
sfText_setCharacterSize(text, 20)

event_ref = Ref{sfEvent}()

# while Bool(sfRenderWindow_isOpen(window))
#     # process events
#     while Bool(sfRenderWindow_pollEvent(window, event_ref))
#         # close window : exit
#         event_ref.x.type == sfEvtClosed && sfRenderWindow_close(window)
#     end
#     # clear the screen
#     sfRenderWindow_clear(window, sfColor_fromRGBA(0,0,0,1))
#     # draw the sprite
#     sfRenderWindow_drawSprite(window, sprite, C_NULL)
#     # draw the text
#     sfRenderWindow_drawText(window, text, C_NULL)
#     # update the window
#     sfRenderWindow_display(window)
# end

sfText_destroy(text)
sfFont_destroy(font)
sfSprite_destroy(sprite)
sfTexture_destroy(texture)
sfRenderWindow_destroy(window)


####################################################################################


t1 = sfMicroseconds(1000000)
t2 = sfMilliseconds(1000)
t3 = sfSeconds(1)

println("*** step 1")
clock = sfClock_create()
sfSleep(t1)
println("*** step 2 ")
seconds_elapsed = sfTime_asSeconds(sfClock_getElapsedTime(clock))

println("elapsed time : $seconds_elapsed sec.")

function get_time(clock ::Ptr{Nothing})
   sfTime_asSeconds(sfClock_getElapsedTime(clock))
end

function restart(clock ::Ptr{Nothing})
    sfTime_asSeconds(sfClock_restart(clock))
end

#sfSleep(t3)
#sfSleep(t3)
t = get_time(clock)
println(t)
#sfSleep(t2)
println(restart(clock))



#################################################################################
# @cenum sfEventType::UInt32 begin
#     sfEvtClosed = 0
#     sfEvtResized = 1
#     sfEvtLostFocus = 2
#     sfEvtGainedFocus = 3
#     sfEvtTextEntered = 4
#     sfEvtKeyPressed = 5
#     sfEvtKeyReleased = 6
#     sfEvtMouseWheelMoved = 7
#     sfEvtMouseWheelScrolled = 8
#     sfEvtMouseButtonPressed = 9
#     sfEvtMouseButtonReleased = 10
#     sfEvtMouseMoved = 11
#     sfEvtMouseEntered = 12
#     sfEvtMouseLeft = 13
#     sfEvtJoystickButtonPressed = 14
#     sfEvtJoystickButtonReleased = 15
#     sfEvtJoystickMoved = 16
#     sfEvtJoystickConnected = 17
#     sfEvtJoystickDisconnected = 18
#     sfEvtTouchBegan = 19
#     sfEvtTouchMoved = 20
#     sfEvtTouchEnded = 21
#     sfEvtSensorChanged = 22
#     sfEvtCount = 23
# end


window = sfWindow_create(sfVideoMode(800, 600,32), "Testing openGL", sfResize | sfClose, C_NULL)

sfWindow_setVerticalSyncEnabled(window,true)
sfWindow_setActive(window, sfTrue)
running = true

while (running)

    while Bool(sfRenderWindow_isOpen(window)) && running
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
                println("**** closed ****")
            elseif event_ref[].type == sfEvtResized
                glViewport(9, 9, event_ref[].size.width, event_ref[].size.height)
                println("*** viewport changed ***")
            end
        end
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        # draw scene


        sfWindow_display(window)
    end

    
end



#sfRenderWindow_destroy(window)