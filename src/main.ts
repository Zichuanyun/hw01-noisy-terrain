import {vec2, vec3} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Square from './geometry/Square';
import Plane from './geometry/Plane';
import Quad from './geometry/Quad';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
var Color = require('color');

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  'lavaColor_0': '#ff0000',
  'lavaColor_1': '#110000',
  'lavaHeight': 2.0,
};

let square: Square;
let plane : Plane;
let lavaQuad : Quad;

let wPressed: boolean;
let aPressed: boolean;
let sPressed: boolean;
let dPressed: boolean;
let planePos: vec2;

let time: number = 0.0;

function loadScene() {
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  let scale: vec2 = vec2.fromValues(100, 100);
  plane = new Plane(vec3.fromValues(0,0,0), scale, 20);
  plane.create();
  lavaQuad = new Quad(vec3.fromValues(0, 0, 0), scale);
  lavaQuad.create();

  wPressed = false;
  aPressed = false;
  sPressed = false;
  dPressed = false;
  planePos = vec2.fromValues(0,0);
}

function main() {
  window.addEventListener('keypress', function (e) {
    // console.log(e.key);
    switch(e.key) {
      case 'w':
      wPressed = true;
      break;
      case 'a':
      aPressed = true;
      break;
      case 's':
      sPressed = true;
      break;
      case 'd':
      dPressed = true;
      break;
    }
  }, false);

  window.addEventListener('keyup', function (e) {
    switch(e.key) {
      case 'w':
      wPressed = false;
      break;
      case 'a':
      aPressed = false;
      break;
      case 's':
      sPressed = false;
      break;
      case 'd':
      dPressed = false;
      break;
    }
  }, false);

  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.addColor(controls, 'lavaColor_0');
  gui.addColor(controls, 'lavaColor_1');
  gui.add(controls, 'lavaHeight', 0.0, 10.0).step(0.05);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 10, -20), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(164.0 / 255.0, 233.0 / 255.0, 1.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/terrain-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/terrain-frag.glsl')),
  ]);

  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  const lavaShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lava-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lava-frag.glsl')),
  ]);

  function processKeyPresses() {
    let velocity: vec2 = vec2.fromValues(0,0);
    if(wPressed) {
      velocity[1] += 1.0;
    }
    if(aPressed) {
      velocity[0] += 1.0;
    }
    if(sPressed) {
      velocity[1] -= 1.0;
    }
    if(dPressed) {
      velocity[0] -= 1.0;
    }
    let newPos: vec2 = vec2.fromValues(0,0);
    vec2.add(newPos, velocity, planePos);
    lambert.setPlanePos(newPos);
    lavaShader.setPlanePos(newPos);
    planePos = newPos;
  }

  // This function will be called every frame
  function tick() {
    camera.update();
    // set time
    lavaShader.setTime(time);
    ++time;

    let lavaCol0 = Color(controls['lavaColor_0']);
    lavaShader.setLavaCol0(vec3.fromValues(
      lavaCol0.rgb().array()[0] / 255.0,
      lavaCol0.rgb().array()[1] / 255.0,
      lavaCol0.rgb().array()[2] / 255.0));

    let lavaCol1 = Color(controls['lavaColor_1']);
    lavaShader.setLavaCol1(vec3.fromValues(
      lavaCol1.rgb().array()[0] / 255.0,
      lavaCol1.rgb().array()[1] / 255.0,
      lavaCol1.rgb().array()[2] / 255.0));

      lavaShader.setLavaHeight(controls['lavaHeight']);

    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    processKeyPresses();
    renderer.render(camera, lavaShader, [
      lavaQuad,
    ]);
    renderer.render(camera, lambert, [
      plane,
    ]);
    renderer.render(camera, flat, [
      square,
    ]);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
