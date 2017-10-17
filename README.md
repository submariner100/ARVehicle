# ARVehicle
ARKit - Small application that controls a vehicle on an horizontal plane.
This was quite an interesting project where a vehicle was made in SceneView out of primitive shapes, this was then placed on 
an horizontal plane. Controls were given to it where the user could steer the vehicle around in his own environments.
On the first commit the vehicle was built and the framework for configuration for ARKit was set up. The horizontal plane was detected
and the vehicle was then coded so that its wheels turn whenever the user turn his iPhone using Accelerometer.
Lessons Learnt - Building a car using the primitives that comes with SceneKit. Using the CMAcceleration to find out which direction
the iPhone is at and using that to create Physicsbody() addbehavour so the user can move the front wheels to steer the vehicle.
Second Commit - Using the renderer didDetectPhysics() method for adding behavour to the vehicle and orientation. 
