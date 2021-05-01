using CSFML.LibCSFML

using ModernGL

mode = sfVideoMode(700, 720, 32)
window = sfRenderWindow_create(mode, "SFML window", sfResize | sfClose, C_NULL)
@assert window != C_NULL
sfWindow_setVerticalSyncEnabled(window,true)
sfWindow_setActive(window, sfTrue)

texture = sfTexture_createFromFile(joinpath("/julia/playgrounds/resources/ghost.jpg"), C_NULL)
@assert texture != C_NULL

sprite = sfSprite_create()
sfSprite_setTexture(sprite, texture, sfTrue)

font = sfFont_createFromFile(joinpath("/julia/playgrounds/resources/NotoSans-Black.ttf"))
@assert font != C_NULL

text = sfText_create()
sfText_setString(text, "The quick brown fox jumps over the lazy dog.")
sfText_setFont(text, font)
sfText_setCharacterSize(text, 20)

event_ref = Ref{sfEvent}()

# complete list of event types :
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
                println("Render window closed.")
            elseif event_ref[].type == sfEvtResized
                glViewport(9, 9, event_ref[].size.width, event_ref[].size.height)
                println("Viewport updated.")
            end
        end

        # Render scene
        sfRenderWindow_clear(window, sfColor_fromRGBA(0,0,0,1))
        sfRenderWindow_drawSprite(window, sprite, C_NULL)
        sfRenderWindow_drawText(window, text, C_NULL)
        sfRenderWindow_display(window)
    end

end


sfText_destroy(text)
sfFont_destroy(font)
sfSprite_destroy(sprite)
sfTexture_destroy(texture)
sfRenderWindow_destroy(window)



