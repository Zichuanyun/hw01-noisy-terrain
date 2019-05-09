#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_LavaHeight;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;

vec2 seed = vec2(332.5, 7732.9);

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

float valueNoise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f;
    u = smoothstep(0.0, 1.0, f);
    // return a*(1.0-u.x)*(1.0-u.y) + b*u.x*(1.0-u.y) + c*(1.0-u.x)*u.y + d*u.x*u.y;
    // return random(i);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float layerValueNoise(int layer, vec2 uv) {
    float col = 0.0;
    for (int i = 0; i < layer; ++i) {
    	vec2 st = uv * pow(2.0, float(i));
        col += valueNoise(st) * pow(0.5, float(i) + 1.0);
    }
    return col;
}

float fbm(vec2 p) {
	return layerValueNoise(2, p);
}

float multiFBM(vec2 p) {
	vec2 q = vec2(fbm(p), fbm(p + vec2(5.2,1.3)));
  vec2 r = vec2(fbm(q + p + vec2(4.5, 3.9)), fbm(q + p + vec2(5.2,1.3)));
    
  return fbm(p + r * 4.0 );
}

float worley_noise(vec2 st) {
  vec2 i_st = floor(st);
  vec2 f_st = fract(st);

  float m_dist = 1.0;
  for (int x = -1; x <= 1; ++x) {
    for (int y = -1; y <= 1; ++y) {
      vec2 neighbor = vec2(float(x),float(y));

      // Random position from current + neighbor place in the grid
      vec2 point = random2(i_st + neighbor, seed);

      vec2 diff = neighbor + point - f_st;

      // Distance to the point
      float dist = length(diff);

      // Keep the closer distance
      m_dist = min(m_dist, dist);
    }
  }
  return m_dist;
}

// IQ style worly
vec3 IQ_worley_noise( in vec2 x ) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    // first pass: regular voronoi
    vec2 mg, mr;
    float md = 8.0;
    for (int j= -1; j <= 1; j++) {
        for (int i= -1; i <= 1; i++) {
            vec2 g = vec2(float(i),float(j));
            vec2 o = random2( n + g, seed );
            vec2 r = g + o - f;
            float d = dot(r,r);

            if( d<md ) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }

    // second pass: distance to borders
    md = 8.0;
    vec2 to_kernel;
    for (int j= -2; j <= 2; j++) {
        for (int i= -2; i <= 2; i++) {
            vec2 g = mg + vec2(float(i),float(j));
            vec2 o = random2( n + g, seed );
            vec2 r = g + o - f;

            if ( dot(mr-r,mr-r)>0.00001 ) {
                md = min(md, dot( 0.5*(mr+r), normalize(r-mr)));
                to_kernel = r - mr;
            }
        }
    }
    // TODO(zichuanyu) make vec2 direction to kernel
    return vec3(md, normalize(to_kernel));
}

float stair(float val, float step) {
  return floor(val * step) / step;
}

float easeOutExpo( float t ) {
    return 1.0 - pow(2.0, -8.0 * t );
}

float final_height_scale = 20.0;

void main()
{
  fs_Pos = vs_Pos.xyz;
  fs_Sine = (sin((vs_Pos.x + u_PlanePos.x) * 3.14159 * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1));
  vec4 modelposition = vec4(vs_Pos.x, fs_Sine * 2.0, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;

  vec2 st = vs_Pos.xz + u_PlanePos.xy;
  float height = 0.0;

  // worley
  float worley_tile = 0.03;
  vec3 iqwn = IQ_worley_noise(st * worley_tile);
  float worley_dis = iqwn.x;
  // isolines
  // worley_contribution = worley_contribution*(0.5 + 0.5*sin(64.0*worley_contribution));
  float angle = (iqwn.y*iqwn.y+iqwn.z*iqwn.z)/(iqwn.y*iqwn.z);
  float num_floor = 15.0;
  float worley_contribution = stair(worley_dis, num_floor);
  float stair_root_dis = 1.0 - fract(worley_dis * num_floor); // distance from the stair edge
  // borders
  float worley_scale = 2.0;
  height += worley_contribution * worley_scale;
  
  // fbm
  float fbm_contribution = multiFBM(st);
  float fbm_scale = 0.1;
  height += fbm_contribution * fbm_scale;

  height /= (worley_scale + fbm_scale);

  vec3 top_col = vec3(0.603, 0.313, 0.203);

  vec3 bottom_cal = vec3(0.909, 0.188, 0.082);
  float color_factor = easeOutExpo(height);
  vec3 color = mix(bottom_cal, top_col, color_factor);
  float normalized_lava_height = u_LavaHeight / final_height_scale;

  color = mix(color, vec3(1.0, 0.0, 0.0), height - normalized_lava_height);

  // ambient
  // lower terrain is lighted by lava, thus less ambient
  float ambient = mix(1.0, sqrt(stair_root_dis), height - normalized_lava_height);
  color *= ambient;

  fs_Col = vec4(vec3(color), 1.0);

  

  height *= final_height_scale;
  modelposition.y = height;
  gl_Position = u_ViewProj * modelposition;
}
