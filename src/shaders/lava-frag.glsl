#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Time;
uniform vec3 u_LavaCol0;
uniform vec3 u_LavaCol1;


in vec3 fs_Pos;


out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// [-1, 1]
vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    vec2 result = -1.0 + 2.0*fract(sin(st)*43758.5453123);
    // result = normalize(result);
    return result;
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

float gradientNoise(vec2 st) {
	vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = dot(random2(i), f - vec2(0.0, 0.0));
    float b = dot(random2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(random2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(random2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
    
    vec2 u = f;
    u = smoothstep(0.0, 1.0, f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);   
}

float layerGradientNoise(int layer, vec2 uv) {    
    float col = 0.0;
    for (int i = 0; i < layer; ++i) {
    	vec2 st = uv * pow(2.0, float(i));
        col += gradientNoise(st) * pow(0.5, float(i) + 1.0);
    }
    col = 0.5 + col * 0.5;
    return col;
}

float fbm(vec2 p) {
	return layerValueNoise(5, p);
    // return layerGradientNoise(6, p);
}

float multiFBM(vec2 p) {
	vec2 q = vec2(fbm(p), fbm(p + vec2(5.2,1.3) + vec2(u_Time / 1000.0) + 0.3 * vec2(u_Time / 1000.0)));
    vec2 r = vec2(fbm(q + p + vec2(4.5, 3.9)), fbm(q + p + vec2(5.2,1.3)));
    
    return fbm(p + r * 4.0 );
}

// void main( out vec4 fragColor, in vec2 fragCoord )
void main()
{
    vec2 uv = vec2(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y);
    uv /= 100.0;
    uv += 1.0;

    // Time varying pixel color
    float val = multiFBM(uv * 3.0);
    float r = val;
    float g = 1.0 - val;
    float b = mix(r, g, val);

    vec3 col = mix(u_LavaCol0, u_LavaCol1, val);

    out_Col = vec4(col, 1.0);
}
