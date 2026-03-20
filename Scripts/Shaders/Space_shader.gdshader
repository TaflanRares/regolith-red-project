shader_type sky;

uniform float star_height = 4.;
uniform float star_size = 6;
uniform float star_blend : hint_range(0.0, 1.0, 0.01) = .1;
uniform float depth_blend : hint_range(0.0, 1.0, 0.01) = .1;
uniform float flare_blend : hint_range(0.0, 1.0, 0.01) = .1;
uniform float star_layers = 2.;

vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
    float sine = sin(rotation);
    float cosine = cos(rotation);
    uv -= pivot;
    uv.x = uv.x * cosine - uv.y * sine;
    uv.y = uv.x * sine + uv.y * cosine;
    uv += pivot;
    return uv;
}

vec2 StarRandomizer(vec2 seed) {
	seed = fract(seed * vec2(123.45, 784.29));
	seed += dot(seed, seed+875.34);
	float x = fract(seed.x * 164.32);
	float y = fract(seed.y * 287.11);
	return vec2(x,y) - .5;
}

float Star(vec2 uv, float flare) {
	float star = .01 / length(uv);
	float rays = max(0, 1. - abs(uv.x * uv.y) * 10000.) * star;
	star += rays * flare;
	return pow(star,3);
}

vec3 StarMaker(vec2 uv){
	vec2 grid_uv = fract(uv)-.2;
	vec2 grid_id = floor(uv);
	vec3 stars = vec3(0);

	for (float y = -1.; y <= 1.; y++){
		for (float x = -1.; x<= 1.; x++) {
			vec2 offset = vec2(x,y);
			vec2 randomstar = StarRandomizer(grid_id + offset);
			float size = (randomstar.x + .6) * star_size;
			float star_flicker = size * (sin(TIME * randomstar.x * 4.) * .2 + .5);
			float flare = smoothstep(star_size * (1. - flare_blend), star_size, size);
			stars += Star(grid_uv - offset - randomstar, flare) * size * star_flicker;
		}
	}
	return stars;
}

void sky() {
	float blend = smoothstep(star_blend, 1, abs(EYEDIR.y));
	float depth = pow(abs(EYEDIR.y), depth_blend);
	for (float i = 1.; i <= star_layers; i+=1.) {
		vec2 uv = EYEDIR.xz / depth * star_height * i;
		uv += StarRandomizer(vec2(i, i+14.)) * i * 3.2;
		if (EYEDIR.y < 0.)
			uv=rotateUV(uv, vec2(0), 170);
		COLOR += StarMaker(uv) * blend;
	}
}
