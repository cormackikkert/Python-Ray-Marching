from OpenGL.GL import *
from events import *
import numpy as np
import pygame
from math import sin, cos
MOVESPEED = 3.0
LOOKSPEED = 0.5
PI = 3.141592635

class Camera:
    @EventAdder
    def __init__(self, posRef, lookRef, **kwargs):
        self.pos = np.array([10.0, 0.0, 0.0])
        self.vel = np.array([0.0, 0.0, 0.0])

        self.posRef = posRef
        self.lookRef = lookRef

        self.look = np.array([0.0, 0.0])
        self.lookvel = np.array([0.0, 0.0])

    def notify(self, event):
        if isinstance(event, KeyEvent): 
            if event.action == 'P':
                if event.type == 'W':
                    self.vel[0] = -MOVESPEED
                elif event.type == 'S':
                    self.vel[0] = MOVESPEED
                elif event.type == 'D':
                    self.vel[1] = MOVESPEED
                elif event.type == 'A':
                    self.vel[1] = -MOVESPEED
                elif event.type == 'Q':
                    self.vel[2] = -MOVESPEED
                elif event.type == 'E':
                    self.vel[2] = MOVESPEED
                elif event.type == 'UP':
                    self.lookvel[0] = LOOKSPEED
                elif event.type == 'DOWN':
                    self.lookvel[0] = -LOOKSPEED
                elif event.type == 'LEFT':
                    self.lookvel[1] = LOOKSPEED
                elif event.type == 'RIGHT':
                    self.lookvel[1] = -LOOKSPEED

            elif event.action == 'R':
                if event.type == 'W':
                    self.vel[0] = 0
                elif event.type == 'S':
                    self.vel[0] = 0
                elif event.type == 'D':
                    self.vel[1] = 0
                elif event.type == 'A':
                    self.vel[1] = 0
                elif event.type == 'Q':
                    self.vel[2] = 0
                elif event.type == 'E':
                    self.vel[2] = 0
                elif event.type == 'UP':
                    self.lookvel[0] = 0
                elif event.type == 'DOWN':
                    self.lookvel[0] = 0
                elif event.type == 'LEFT':
                    self.lookvel[1] = 0
                elif event.type == 'RIGHT':
                    self.lookvel[1] = 0

        if isinstance(event, TickEvent):
            # Position movements
            forward = np.array([cos(self.look[1]), sin(self.look[1]), 0.0])
            strafe = np.cross(forward, np.array([0.0, 0.0, -1.0]), )

            self.pos += self.vel[0] * forward * event.time
            self.pos += self.vel[1] * strafe * event.time
            self.pos += self.vel[2] * np.array([0.0, 0.0, -1.0]) * event.time
            glUniform3f(self.posRef, self.pos[1], self.pos[2], self.pos[0])

            self.look += self.lookvel * event.time
            self.look[0] %= 2 * PI;
            self.look[1] %= 2 * PI;
            glUniform2f(self.lookRef, self.look[0], self.look[1])



