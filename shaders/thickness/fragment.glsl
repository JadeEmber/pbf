#version 430 core

// input from vertex shader
in vec2 fTexcoord;
in vec3 fPosition;
flat in uint id;

layout (location = 0) out float thickness;
layout (location = 1) out vec3 noise;

layout (binding = 0) uniform sampler2D depthtex;

uniform bool usenoise;

// projection and view matrix
layout (binding = 0, std140) uniform TransformationBlock {
	mat4 viewmat;
	mat4 projmat;
};

//
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
// 

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

// linearize a depth value in order to determine a meaningful difference
float linearizeDepth (in float d)
{
	const float f = 1000.0f;
	const float n = 1.0f;
	return (2 * n) / (f + n - d * (f - n));
}

void main (void)
{
	float r = dot (fTexcoord, fTexcoord);
	if (r > 1)
		discard;	
	thickness = 1;
	if (usenoise)
	{
		vec3 normal = vec3 (fTexcoord, -sqrt (1 - r));
		vec4 fPos = vec4 (fPosition - 0.1 * normal, 1.0);
		vec4 clipPos = projmat * fPos;
		float depth = linearizeDepth (clipPos.z / clipPos.w);

		vec2 tmp = fTexcoord * fTexcoord;
		float dd = depth - linearizeDepth (texture (depthtex, fTexcoord).x);
		noise = exp (-tmp.x - tmp.y + dd * dd) * vec3 (snoise ((fTexcoord + 1 + 16.0 * float (id)) * 0.75),
				  								   	   snoise ((fTexcoord + 3 + 16.0 * float (id)) * 0.75),
				  								   	   snoise ((fTexcoord + 5 + 16.0 * float (id)) * 0.75));
	}
}
