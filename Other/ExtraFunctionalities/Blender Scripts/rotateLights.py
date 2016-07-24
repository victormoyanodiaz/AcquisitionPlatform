
import bpy
from math import *
import mathutils
import time


stepsAzimuth= 2 #20 steps for left limit to right limit.
stepsInclination= 3 #10 steps to upper limit to lower limit.

light = bpy.data.objects["Point"]

#init distance of rotation to the y position of the light
radiiRotation= light.location[1];

limitDegrees= 120
limitRadians= limitDegrees*2*pi/360

stepAzimuth= 2*limitRadians/stepsAzimuth #the 2 multiplication is for going from the -limit to the limit.
stepInclination= 2*limitRadians/stepsInclination #the 2 multiplication is for going from the -limit to the limit. 

azimuth= [-limitRadians + i*stepAzimuth for i in range(0,stepsAzimuth+1)]
inclination= [-limitRadians + i*stepInclination for i in range(0,stepsInclination+1)]
light = bpy.data.objects["Point"]

#init distance of rotation to the y position of the light
radiiRotation= -light.location[1];

for a in azimuth:
    for i in inclination:
        xPosition= sin(a)*sin(i)*radiiRotation
        yPosition= cos(a)*sin(i)*radiiRotation
        zPosition= cos(i)*radiiRotation

    
        newPosition= mathutils.Vector((xPosition,yPosition,zPosition))
        light.location= newPosition
    
        bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)
        bpy.context.scene.update()
    
        directory= 'C:/Users/Victor/Desktop/Platform/AcquisitionPlatform/Other/ExtraFunctionalities/LightRecovering/lightPoint/'
        #directory= 'C:/Users/vmoyano/Documents/GitHub/AcquisitionPlatform/Other/ExtraFunctionalities/renderedImages/lightPoint/'

        bpy.data.scenes["Scene"].render.filepath = directory+ 'Azimuth_%f_Inclination_%f_x_%f_y_%f_z_%f.jpg' % (a*360/(2*pi), i*360/(2*pi), xPosition, -yPosition, -zPosition)   
        bpy.ops.render.render( write_still=True )
    