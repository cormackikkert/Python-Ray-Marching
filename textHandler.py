# From https://archives.seul.org/pygame/users/Aug-2005/msg00028.html

"""
AB_RenderFont.py
Draws text on the screen.
Closely based on (ie. nearly ripped off from) a tutorial with the
following header:

Ported to PyOpenGL 2.0 by Brian Leair 18 Jan 2004
This code was created by Jeff Molofee 2000
The port was based on the PyOpenGL tutorial and from the
PyOpenGLContext (tests/glprint.py).
If you've found this code useful, please let me know (email Brian Leair
at telcom_sage@xxxxxxxxx).
See original source and C based tutorial at <http://nehe.gamedev.net>.
"""

##### INCLUDED MODULES #####

from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.WGL import *
import win32ui, sys

##### CLASSES #####

class FontKeeper:
    def __init__(self,screensize=[800,600],color=[0.4,0.4,0.8],fontname="Courier",size=24):
        """Handles drawing text on the screen."""
        self.BuildFont(fontname,-size)
        self.screensize = screensize ## Used for reversing draw coords.
        self.color = color

    def BuildFont(self,fontname="Times New Roman",width=0,size=24,weight=800):
        """Load a font as a set of OpenGL drawing lists, for quick
        drawing of each letter."""
        wgldc = wglGetCurrentDC()
        hDC = win32ui.CreateDCFromHandle(wgldc)
        properties = {"name":fontname,"width":width,"height":size,"weight":weight}
        self.fontlists = glGenLists(96)
        font = win32ui.CreateFont(properties)
        oldfont = hDC.SelectObject (font) ## ?
        wglUseFontBitmaps(wgldc,32,96,self.fontlists)
        hDC.SelectObject (oldfont) ## ?

    def Write(self,text="",coords=[0,50]):
        """Draw text on the screen. Coords = actual screen coords.
        Y gets reversed because OpenGL does too, treating LL corner as
        Y=0."""
        if not text:
            return
        glColor(self.color)
        glRasterPos2i(coords[0],self.screensize[1]-coords[1])
        glPushAttrib(GL_LIST_BIT)
        glListBase(self.fontlists - 32)
        glCallLists(text)
        glPopAttrib()