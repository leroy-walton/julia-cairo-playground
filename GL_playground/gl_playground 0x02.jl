import GLFW
using ModernGL
include("gl_utils.jl")

w = 1000
h = 700

GLFW.Init()
window = GLFW.CreateWindow( w, h, "GL Playground")
GLFW.MakeContextCurrent(window)
GLFW.ShowWindow(window)

glViewport( 0, 0, w, h)

println(createcontextinfo())
