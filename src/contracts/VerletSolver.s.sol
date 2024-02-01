pragma solidity ^0.8.0;
import './ABDKMath64x64.sol';

contract VerletSolver {
    struct Vector {
        int x;
        int y;
    }

    struct VectorInt128 {
        int128 x;
        int128 y;
    }

    struct VerletObject {
        Vector position_current;
        Vector position_old;
        Vector acceleration;
        uint radius;
    }

    struct Mass {
        Vector position;
        int mass;
        int radius;
    }

    //a public function that takes in a verlet object and updates its position
    function updatePosition(VerletObject memory obj, int dt) public pure returns (VerletObject memory) {
        Vector memory velocity = Vector(
            obj.position_current.x - obj.position_old.x,
            obj.position_current.y - obj.position_old.y
        );
        obj.position_old = obj.position_current;
        obj.position_current.x = obj.position_current.x + velocity.x + obj.acceleration.x * dt * dt;
        obj.position_current.y = obj.position_current.y + velocity.y + obj.acceleration.y * dt * dt;

        //obj.acceleration.x = 0;
        //obj.acceleration.y = 0;

        return obj;
    }

    function tick(
        VerletObject memory obj,
        Mass[] memory bodies,
        int dt
    ) public pure returns (VerletObject memory, Vector memory, Mass[] memory) {
        obj = applyGravity(obj, 1);

        Vector memory contactPoint;
        bool collision;

        (obj, contactPoint) = applyConstraintsCircularContainer(obj);

        (obj, bodies, collision) = applyConstraintsPachinko(obj, bodies);
        if(collision) {
            contactPoint = Vector(-100, -100);
        }
        obj = updatePosition(obj, dt);

        return (obj, contactPoint, bodies);
    }

    function applyGravitationalBodies(
        VerletObject memory obj,
        Mass[] memory bodies
    ) public pure returns (VerletObject memory) {
        for (uint i = 0; i < bodies.length; i++) {
            Vector memory bodyPosition = bodies[i].position;
            int bodyMass = bodies[i].mass;

            int128 posX = ABDKMath64x64.fromInt(obj.position_current.x);
            int128 posY = ABDKMath64x64.fromInt(obj.position_current.y);
            int128 centerX = ABDKMath64x64.fromInt(bodyPosition.x);
            int128 centerY = ABDKMath64x64.fromInt(bodyPosition.y);

            int128 distance = getDistance(posX, posY, centerX, centerX);
            int128 force = ABDKMath64x64.div(ABDKMath64x64.fromInt(bodyMass), ABDKMath64x64.mul(distance, distance));
            int128 nX = ABDKMath64x64.div(ABDKMath64x64.sub(centerX, posX), distance);
            int128 nY = ABDKMath64x64.div(ABDKMath64x64.sub(centerY, posY), distance);

            obj.acceleration.x += ABDKMath64x64.toInt(ABDKMath64x64.mul(force, nX));
            obj.acceleration.y += ABDKMath64x64.toInt(ABDKMath64x64.mul(force, nY));
        }

        return obj;
    }

    function accelerate(VerletObject memory obj, Vector memory acceleration) public pure returns (VerletObject memory) {
        obj.acceleration.x = acceleration.x;
        obj.acceleration.y = acceleration.y;
        return obj;
    }

    function applyGravity(VerletObject memory obj, int gravity) public pure returns (VerletObject memory) {
        obj.acceleration.y += gravity;
        return obj;
    }

    struct CollisionData64x64 {
        VectorInt128 pos;
        VectorInt128 center;
    }

    struct CollisionAdjustment {
        int128 newX;
        int128 newY;
        int128 nX;
        int128 nY;
    }

    function applyConstraintsPachinko(
        VerletObject memory obj,
        Mass[] memory pegs     
    ) public pure returns (VerletObject memory, Mass[] memory, bool) {
        bool collision = false;

        for (uint i = 0; i < pegs.length; i++) {
            Vector memory pegPosition = pegs[i].position;
            uint pegRadius = uint(pegs[i].radius);

            CollisionData64x64 memory collisionData = CollisionData64x64(
                VectorInt128(ABDKMath64x64.fromInt(obj.position_current.x), ABDKMath64x64.fromInt(obj.position_current.y)),
                VectorInt128(ABDKMath64x64.fromInt(pegPosition.x), ABDKMath64x64.fromInt(pegPosition.y))
            );

            uint objRadius = obj.radius;
            int128 distance = getDistance(collisionData.pos.x, collisionData.pos.y, collisionData.center.x, collisionData.center.y);
            //If distance of object is less then radius of peg plus radius of object
            if (distance < ABDKMath64x64.fromUInt(pegRadius + obj.radius) && !collision) {
                collision = true;
                //int nX = (obj.position_current.x - center.x) / int(distance);
                
                (CollisionAdjustment memory collisionAdjustment) = unstick64x64(
                    collisionData.center.x,
                    collisionData.center.y,
                    collisionData.pos.x,
                    collisionData.pos.y,
                    distance,
                    pegRadius,
                    objRadius
                );
                obj.position_current.x = ABDKMath64x64.toInt(collisionAdjustment.newX);
                obj.position_current.y = ABDKMath64x64.toInt(collisionAdjustment.newY);

                //Acceleration becomes the normal line of the collision 
                obj.acceleration.x = -ABDKMath64x64.toInt(collisionAdjustment.nX) * int((90 - obj.radius) / 30);
                obj.acceleration.y = ABDKMath64x64.toInt(collisionAdjustment.nY) - 15;

                //Remove the peg that was hit from the array
                pegs = removeItem(pegs, i);
            }
        }
        return (obj, pegs, collision);
    }

    //Given a collision between two objects, return the new position of the object after the collision
    function unstick64x64(
        int128 centerX,
        int128 centerY,
        int128 posX,
        int128 posY,
        int128 distance,
        uint collisionObjectMass,
        uint objectRadius
    ) internal pure returns (CollisionAdjustment memory) {
        int128 nX = ABDKMath64x64.div(ABDKMath64x64.sub(centerX, posX), distance);
        int128 nY = ABDKMath64x64.div(ABDKMath64x64.sub(centerY, posY), distance);

        int128 newX = ABDKMath64x64.sub(
            centerX,
            ABDKMath64x64.mul(nX, ABDKMath64x64.fromUInt(collisionObjectMass + objectRadius))
        );
        int128 newY = ABDKMath64x64.sub(
            centerY,
            ABDKMath64x64.mul(nY, ABDKMath64x64.fromUInt(collisionObjectMass + objectRadius))
        );

        return CollisionAdjustment(newX, newY, nX, nY);
    }

    function removeItem(Mass[] memory array, uint index) internal pure returns (Mass[] memory) {
        require(index < array.length, 'Index out of bounds');

        Mass[] memory newArray = new Mass[](array.length);

        for (uint i = 0; i < newArray.length; i++) {
            if (i != index) {
                newArray[i] = array[i];
            }
        }

        return newArray;
    }

    //apply constraints using floating point math
    function applyConstraintsCircularContainer(
        VerletObject memory obj
    ) public pure returns (VerletObject memory, Vector memory) {
        int128 centerX = ABDKMath64x64.fromInt(1280 / 4);
        int128 centerY = ABDKMath64x64.fromInt(360);

        int128 boundaryRadius = ABDKMath64x64.fromUInt(320);
        int128 objRadius = ABDKMath64x64.fromUInt(obj.radius);

        int128 posX = ABDKMath64x64.fromInt(obj.position_current.x);
        int128 posY = ABDKMath64x64.fromInt(obj.position_current.y);

        int128 distance = getDistance(posX, posY, centerX, centerX);

        Vector memory contactPoint;
        if (distance > ABDKMath64x64.sub(boundaryRadius, objRadius)) {
            //int nX = (obj.position_current.x - center.x) / int(distance);
            int128 nX = ABDKMath64x64.div(ABDKMath64x64.sub(centerX, posX), distance);
            int128 nY = ABDKMath64x64.div(ABDKMath64x64.sub(centerY, posY), distance);

            int128 newX = ABDKMath64x64.sub(
                centerX,
                ABDKMath64x64.mul(nX, ABDKMath64x64.sub(boundaryRadius, objRadius))
            );
            int128 newY = ABDKMath64x64.sub(
                centerY,
                ABDKMath64x64.mul(nY, ABDKMath64x64.sub(boundaryRadius, objRadius))
            );
            obj.position_current.x = ABDKMath64x64.toInt(newX);
            obj.position_current.y = ABDKMath64x64.toInt(newY);

            //Acceleration becomes the normal line of the collision

            obj.acceleration.x = ABDKMath64x64.toInt(nX);
            obj.acceleration.y = ABDKMath64x64.toInt(nY);

            if (obj.radius <= 10) {
                obj.radius = obj.radius + 1;
            } else {
                obj.radius = obj.radius - 1;
            }

            contactPoint = Vector(ABDKMath64x64.toInt(posX), ABDKMath64x64.toInt(posY));
        } else {
            contactPoint = Vector(0, 0);
        }

        return (obj, contactPoint);
    }

    function getDistance(
        int128 positionX,
        int128 positionY,
        int128 centerX,
        int128 centerY
    ) public pure returns (int128) {
        int128 dx = getDistanceOnAxis(positionX, centerX);
        int128 dy = getDistanceOnAxis(positionY, centerY);

        int128 combined = ABDKMath64x64.add(ABDKMath64x64.mul(dx, dx), ABDKMath64x64.mul(dy, dy));
        return ABDKMath64x64.sqrt(combined);
    }

    function getDistanceOnAxis(int128 x1, int128 x2) public pure returns (int128) {
        int128 dx;
        if (x1 < x2 && x1 > 0) {
            dx = ABDKMath64x64.sub(x2, x1);
        } else if (x1 > x2) {
            dx = ABDKMath64x64.sub(x1, x2);
        } else if (x1 < 0) {
            dx = ABDKMath64x64.add(ABDKMath64x64.abs(x1), x2);
        }
        return dx;
    }
}
