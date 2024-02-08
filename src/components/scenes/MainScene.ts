import { Tevm } from 'tevm'
import { VerletSolver, } from '../../contracts/VerletSolver.s.sol'
import { DEFAULT_HEIGHT, DEFAULT_WIDTH } from '../constants'
import Phaser from "phaser";

//https://www.youtube.com/shorts/6gzEGS9JMYg

interface Vector {
  x: number
  y: number
}

interface Circle {
  position: Vector
  velocity: Vector
  acceleration: number
  radius: number
  graphics: Phaser.GameObjects.Graphics
}

interface VerletObject {
  position_current: Vector
  position_old: Vector
  acceleration: Vector
  graphics: Phaser.GameObjects.Graphics
  radius: number
}

interface Mass {
  position: Vector,
  mass: number,
  radius : number
}

const INITIAL_CIRCLE_POSITION_X = DEFAULT_WIDTH / 4
const INITIAL_CIRCLE_POSITION_Y = DEFAULT_HEIGHT / 4
const CIRCLE_RADIUS = 320

const detuneValues = [
  0, 200, 500, 1000, 1200, 1400, 1700, 2200, 2400, 2600, 2900, 3400, 3600, 3800, 4100,
  //reverse order
  4100, 3800, 3600, 3400, 2900, 2600, 2400, 2200, 1700, 1400, 1200, 1000, 500, 200, 0,
  100, 600, 800, 900, 1300, 1800, 2000, 2100, 2500, 3000, 3200, 3300, 3700, 4200,
  //reverse order
  3700, 3300, 3200, 3000, 2500, 2100, 2000, 1800, 1300, 900, 800, 600, 100
];

export default class MainScene extends Phaser.Scene {
  constructor() {
    super({ key: 'MainScene' })
  }

  tevm?: Tevm

  circle: VerletObject
  bodies: Mass[] = []


  initiatePegs() {
    //create pegs
    for (let i = 0; i < 10; i++) {
      for (let j = 0; j < 5; j++) {
        this.bodies.push({
          position: {
            x: 100 + i * 50,
            y: 300 + j * 50,
          }, mass: 1,
          radius : 10
        })
      }
    }
  }

  preload() {
    this.load.audio('bell', 'assets/sounds/bell.mp3')
  }
  async create() {
    var graphics = this.add.graphics()

    var graphicsSquare = this.add.graphics()

    var fillColor = 0xfffffff // Fill color (red)
    graphics.fillStyle(fillColor)


    graphicsSquare.lineStyle(2, 0x0000ff, 1)
    //graphicsSquare.strokeRect(INITIAL_CIRCLE_POSITION_X / 2, INITIAL_CIRCLE_POSITION_Y / 2, INITIAL_CIRCLE_POSITION_X, INITIAL_CIRCLE_POSITION_X)
    graphicsSquare.fillStyle(0x808080)
    graphicsSquare.fillCircle(INITIAL_CIRCLE_POSITION_X, DEFAULT_HEIGHT / 2, CIRCLE_RADIUS)

    this.circle = {
      position_current: { x: INITIAL_CIRCLE_POSITION_X + CIRCLE_RADIUS / 2, y: 160 },
      position_old: { x: INITIAL_CIRCLE_POSITION_X + CIRCLE_RADIUS / 2, y: DEFAULT_HEIGHT / 2 },
      acceleration: { x: 0, y: 0 },
      graphics: graphics,
      radius: 40
    }
    this.bodies = []
    this.sound.add('bell')
    this.initiatePegs()
    this.displayPegs()
  }

  dt = 0

  detuneIndex = 0
  playSweetSound() {


    //this.sound.play('bell', { detune: detuneValues[this.detuneIndex] })

    //increment detuneIndex going back to zero at the end
    this.detuneIndex = (this.detuneIndex + 1) % detuneValues.length
  }

  displayPegs() {
    this.bodies.forEach(body => {
      this.circle.graphics.fillStyle(0xfffffff)
      this.circle.graphics.setDepth(10)
      this.circle.graphics.fillCircle(body.position.x, body.position.y, body.radius)
    })
  }
  
  async update(t, dt) {
    if (!this.tevm) {
      this.tevm = await Tevm.create()
      return
    }

    if (t < 8000) {
      return
    }

    
    const golfBall = {
      position_current: this.circle.position_current,
      position_old: this.circle.position_old,
      acceleration: this.circle.acceleration,
      radius: this.circle.radius
    }

    //let res = await this.tevm.runScript(Golf.read.tickCircle(golfBall))
    let res = await this.tevm.runScript(VerletSolver.read.tick(golfBall, this.bodies, 1))


    //res.data[0] is position vector
    this.circle.position_current.x = Number(res.data[0].position_current.x)
    this.circle.position_current.y = Number(res.data[0].position_current.y)
    this.circle.position_old.x = Number(res.data[0].position_old.x)
    this.circle.position_old.y = Number(res.data[0].position_old.y)
    this.circle.acceleration.x = Number(res.data[0].acceleration.x)
    this.circle.acceleration.y = Number(res.data[0].acceleration.y)
    this.circle.radius = Number(res.data[0].radius)


    this.circle.graphics.clear()
    this.circle.graphics.fillStyle(0xfffffff)
    this.circle.graphics.setDepth(10)
    this.circle.graphics.fillCircle(Number(res.data[0].position_current.x), Number(res.data[0].position_current.y), this.circle.radius)
    
    if(Number(res.data[1].x) == -100){
      this.playSweetSound()
    }

    this.bodies = res.data[2].map((body, index) => {
      return {
        position: {
          x: Number(body.position.x),
          y: Number(body.position.y)
        },
        mass: Number(body.mass),
        radius : Number(body.radius)
      }
    })
    this.displayPegs()
    //res.data[1] is velocity vector



    return
  }
}
