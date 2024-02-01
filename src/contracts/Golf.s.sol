pragma solidity ^0.8.0;

contract Golf {
    struct Vector {
        int x;
        int y;
    }

    struct Ball {
        Vector position;
        Vector velocity;
        int acceleration;
        uint radius;        
    }

    struct Hole {
        Vector position;
        uint radius;
    }


    //Lower numbers in phaser display higher (its inverted)
    int constant GRAVITY = 5;
    int constant leftbound = 160;
    int constant rightbound = 480;
    int constant topbound = 90;
    int constant bottombound = 410;
    int constant centerX = 320;
    int constant centerY = 240;
    
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getDistanceFromCenterOfCircle(uint dx, uint dy) public pure returns (uint) {
        uint distance = sqrt(dx * dx + dy * dy);
        return distance;
    }

    function intToUint(int x) private pure returns (uint) {
        if(x < 0) {
            return uint(-x);
        }
        else {
            return uint(x);
        }
    }

    function getDistanceOnAxis(int x1, int x2) public pure returns (uint) {
        uint dx;
        if(x1 < x2 && x1 > 0){
            dx = uint(x2 - x1);
        } else if (x1 > x2) {
            dx = uint(x1 - x2);
        } else if (x1 < 0 ) {
            dx = intToUint(x1) + uint(x2);
        }
        return dx;
    }

    function tickCircle(Ball memory _ball) public pure returns (Ball memory) {
        // Update the ball's position based on the direction
        _ball.position.x += _ball.velocity.x;
        _ball.position.y += _ball.velocity.y;

        _ball.velocity.x = _ball.velocity.x + _ball.acceleration;
        _ball.velocity.y = _ball.velocity.y + _ball.acceleration + GRAVITY;

        uint dx = getDistanceOnAxis(_ball.position.x, centerX);
        uint dy = getDistanceOnAxis(_ball.position.y, centerY);
        uint distance = getDistanceFromCenterOfCircle(dx, dy);
        
        if(distance >= 160)
        {
            //switch direction of ball 
            _ball.velocity.x = -_ball.velocity.x;
            _ball.velocity.y = -_ball.velocity.y;

            //solidity version of  obj.position = m_constraint_center - n * (m_constraint_radius - obj.radius);
            uint n = (distance - 160) / _ball.radius;
            _ball.position.x = centerX - int(n * (_ball.radius - 160));
            _ball.position.y = centerY - int(n * (_ball.radius - 160));
            
        }
        return _ball;
    }

    function tick(Ball memory _ball) public pure returns (Ball memory) {
        // Update the ball's position based on the direction
        _ball.position.x += _ball.velocity.x;
        _ball.position.y += _ball.velocity.y;

        _ball.velocity.x = _ball.velocity.x + _ball.acceleration;
        _ball.velocity.y = _ball.velocity.y + _ball.acceleration + GRAVITY;

        if(_ball.position.x < leftbound) {
            _ball.position.x = leftbound;
            _ball.velocity.x = -_ball.velocity.x;
        }else if(_ball.position.x > rightbound) {
            _ball.position.x = rightbound;
            _ball.velocity.x = -_ball.velocity.x;
        } else if(_ball.position.y < topbound) {
            _ball.position.y = topbound;
            _ball.velocity.y = -_ball.velocity.y;
        } else if(_ball.position.y > bottombound) {
            _ball.position.y = bottombound;
            _ball.velocity.y = -_ball.velocity.y;
        }
        return _ball;
    }

    function isBallInHole(Ball memory _ball, Hole memory _hole) public pure returns (bool) {
        // Calculate the distance between the ball's center and the hole's center
        int distanceX = _ball.position.x - _hole.position.x;
        int distanceY = _ball.position.y - _hole.position.y;
        int distanceSquared = distanceX * distanceX + distanceY * distanceY;

        // If the distance is less than the hole's radius, the ball is in the hole
        if (distanceSquared <= int256(_hole.radius * _hole.radius)) {
            return true;
        } else {
            return false;
        }
    }
}