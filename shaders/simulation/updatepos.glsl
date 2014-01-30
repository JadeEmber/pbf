// include.glsl is included here
#line 3

layout (local_size_x = 256) in;

struct ParticleInfo
{
	vec3 position;
	vec4 oldposition;
};

layout (std430, binding = 0) buffer ParticleBuffer
{
	ParticleInfo particles[];
};

layout (std430, binding = 1) readonly buffer LambdaBuffer
{
	float lambdas[];
};

layout (std430, binding = 2) writeonly buffer AuxBuffer
{
	vec4 auxdata[];
};

layout (binding = 0) uniform isampler3D gridtexture;
layout (binding = 1) uniform isamplerBuffer flagtexture;


float Wpoly6 (float r)
{
	if (r > h)
		return 0;
	float tmp = h * h - r * r;
	return 1.56668147106 * tmp * tmp * tmp / (h*h*h*h*h*h*h*h*h);
}

float Wspiky (float r)
{
	if (r > h)
		return 0;
	float tmp = h - r;
	return 4.774648292756860 * tmp * tmp * tmp / (h*h*h*h*h*h);
}

vec3 gradWspiky (vec3 r)
{
	float l = length (r);
	if (l > h)
		return vec3 (0, 0, 0);
	float tmp = h - l;
	return (-3 * 4.774648292756860 * tmp * tmp) * r / (l * h*h*h*h*h*h);
}

const ivec3 gridoffsets[27] = {
	ivec3 (-1, -1, -1),
	ivec3 (-1, -1, 0),
	ivec3 (-1, -1, 1),
	ivec3 (-1, 0, -1),
	ivec3 (-1, 0, 0),
	ivec3 (-1, 0, 1),
	ivec3 (-1, 1, -1),
	ivec3 (-1, 1, 0),
	ivec3 (-1, 1, 1),
	ivec3 (0, -1, -1),
	ivec3 (0, -1, 0),
	ivec3 (0, -1, 1),
	ivec3 (0, 0, -1),
	ivec3 (0, 0, 0),
	ivec3 (0, 0, 1),
	ivec3 (0, 1, -1),
	ivec3 (0, 1, 0),
	ivec3 (0, 1, 1),
	ivec3 (1, -1, -1),
	ivec3 (1, -1, 0),
	ivec3 (1, -1, 1),
	ivec3 (1, 0, -1),
	ivec3 (1, 0, 0),
	ivec3 (1, 0, 1),
	ivec3 (1, 1, -1),
	ivec3 (1, 1, 0),
	ivec3 (1, 1, 1)
};

#define FOR_EACH_NEIGHBOUR(var) for (int o = 0; o < 27; o++) {\
		vec3 ngridpos = gridpos + gridoffsets[o] / GRID_SIZE;\
		int var = texture (gridtexture, ngridpos).x;\
		if (var == -1) continue;\
		do { if (var != particleid) {
#define END_FOR_EACH_NEIGHBOUR(var)	} var++; } while (texelFetch (flagtexture, var).x == 0);}

void main (void)
{
	uint particleid;
	particleid = gl_GlobalInvocationID.x;

	vec3 position = particles[particleid].position;
	
	// compute grid id as hash value
	vec3 gridpos = floor (position) / GRID_SIZE;
	
	vec3 deltap = vec3 (0, 0, 0);
	
	float lambda = lambdas[particleid];
		
	FOR_EACH_NEIGHBOUR(j)
	{
		vec3 position_j = particles[j].position;
		
		float scorr = (Wpoly6 (length (position - position_j)) / Wpoly6 (tensile_instability_h));
		scorr *= scorr;
		scorr *= scorr;
		scorr = -tensile_instability_k * scorr;  
	
		// accumulate position corrections (part of equation 12)
		deltap += (lambda + lambdas[j] + scorr) * gradWspiky (position - position_j);
	}
	END_FOR_EACH_NEIGHBOUR(j)

	position += deltap / rho_0;

	// collision detection begin
	vec3 wall = vec3 (16, 0, 16);
	position = clamp (position, vec3 (0, 0, 0) + wall, GRID_SIZE - wall);
	// collision detection end
	
	particles[particleid].position = position;
}
