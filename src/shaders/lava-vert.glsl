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

vec2 seed = vec2(332.5, 7732.9);

void main()
{
  fs_Pos = vs_Pos.xyz;
  vec4 modelposition = vec4(vs_Pos.x, u_LavaHeight, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}
