import pygame
from OpenGL.GL import *
from OpenGL.GL import shaders
from OpenGL.GLU import *
from OpenGL.GLUT import *
from events import *
from pygame.locals import *
import time
import numpy as np
from camera import *
from constants import *
from gui import *

frame_num = 0

if __name__ == "__main__":
    pygame.init()
    window = pygame.display.set_mode(win_size, OPENGL | DOUBLEBUF)

    try:
        fragment = shaders.compileShader(open("raymarch.glsl"), GL_FRAGMENT_SHADER)
    except (GLError, RuntimeError) as err:
        print("Failed: ", err)

    shader = shaders.compileProgram(fragment)
    glUseProgram(shader)

    resRef  = glGetUniformLocation(shader, "iResolution")
    timeRef = glGetUniformLocation(shader, "iTime")
    posRef = glGetUniformLocation(shader, "cam")
    lookRef = glGetUniformLocation(shader, "lookRot")

    ca = glGetUniformLocation(shader, "const_a")
    cb = glGetUniformLocation(shader, "const_b")
    cc = glGetUniformLocation(shader, "const_c")
    cd = glGetUniformLocation(shader, "const_d")
    ce = glGetUniformLocation(shader, "const_e")
    cf = glGetUniformLocation(shader, "const_f")
    cg = glGetUniformLocation(shader, "const_g")
    ch = glGetUniformLocation(shader, "const_h")
    ci = glGetUniformLocation(shader, "const_i")
    cj = glGetUniformLocation(shader, "const_j")
    ta = glGetUniformLocation(shader, "bool_a")

    glUniform2fv(resRef, 1, frac_size)
    fullscreen_quad = np.array([-1.0, -1.0, 0.0, 1.0, -1.0, 0.0, -1.0, 1.0, 1.0, 1.0, 1.0, 0.0], dtype=np.float32)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, fullscreen_quad)
    glEnableVertexAttribArray(0)

    clock = pygame.time.Clock()
    controller = EventManager()

    items = [KeyboardController(evManager=controller), 
             Camera(posRef, lookRef, evManager=controller),
             Scroller(frac_size[0] + 50, 10, 150, [-1, 1], lambda x : glUniform1f(ca, x), window, evManager=controller),
             Scroller(frac_size[0] + 100, 10, 150, [-1, 1], lambda x : glUniform1f(cb, x), window, evManager=controller),
             Scroller(frac_size[0] + 150, 10, 150, [-1, 1], lambda x : glUniform1f(cc, x), window, evManager=controller),
             Scroller(frac_size[0] + 50, 170, 150, [0, 2*PI], lambda x : glUniform1f(cd, x), window, evManager=controller),
             Scroller(frac_size[0] + 100, 170, 150, [0, 2*PI], lambda x : glUniform1f(ce, x), window, evManager=controller),
             Scroller(frac_size[0] + 150, 170, 150, [0, 2*PI], lambda x : glUniform1f(cf, x), window, evManager=controller),
             Scroller(frac_size[0] + 50, 330, 150, [0, 2*PI], lambda x : glUniform1f(cg, x), window, evManager=controller),
             Scroller(frac_size[0] + 100, 330, 150, [0, 2*PI], lambda x : glUniform1f(ch, x), window, evManager=controller),
             Scroller(frac_size[0] + 150, 330, 150, [0, 2*PI], lambda x : glUniform1f(ci, x), window, evManager=controller),
             Scroller(50, 10, 150, [0.8, 3.0], lambda x : glUniform1f(cj, x), window, evManager=controller),
             Toggle(50, 170, 100, 50, lambda x : glUniform1i(ta, int(x)), window, evManager=controller)]
            #  Button("print", 
            #     lambda : print(glGetUniform1f(shader, ca),
            #                     glGetUniform1f(shader, ca)window, rect=Rect(50, 250, 100, 50)]
    
    
    for item in items:
        controller.registerListener(item)

    glutInit()

    while True:
        glUseProgram(shader)
        controller.push(TickEvent(clock.get_time() / 1000))
		# for i in range(3):
		# 	shader.set(str(i), keyvars[i])
		# shader.set('v', np.array(keyvars[3:6]))
		# shader.set('pos', mat[3,:3])

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glUniform1f(timeRef, pygame.time.get_ticks() / 1000.0)
		# glUniformMatrix4fv(matID, 1, False, mat)
		# glUniformMatrix4fv(prevMatID, 1, False, prevMat)
		# prevMat = np.copy(mat)

        
        # glPushMatrix()
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
        # glPopMatrix()

        glUseProgram(0)
        # glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        controller.push(RenderEvent())
        pygame.display.flip()

        clock.tick(max_fps)
        frame_num += 1
        # print(clock.get_fps())