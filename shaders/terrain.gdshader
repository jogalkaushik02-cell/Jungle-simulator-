shader_type spatial;
render_mode cull_disabled;

uniform sampler2D forest_albedo : source_color, filter_linear_mipmap;
uniform sampler2D forest_normal : filter_linear_mipmap;
uniform sampler2D mud_albedo : source_color, filter_linear_mipmap;
uniform sampler2D mud_normal : filter_linear_mipmap;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap;
uniform sampler2D rock_normal : filter_linear_mipmap;
uniform sampler2D snow_albedo : source_color, filter_linear_mipmap;
uniform sampler2D snow_normal : filter_linear_mipmap;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = wpos.xz * 0.14;
	float slope = 1.0 - abs(normalize(wnorm).y);
	float h = wpos.y;

	float w_snow = smoothstep(22.0, 30.0, h);
	float w_rock = smoothstep(0.10, 0.26, slope) * (1.0 - w_snow);
	float w_mud = (1.0 - smoothstep(1.0, 2.4, h)) * (1.0 - w_rock);
	float w_forest = clamp(1.0 - w_snow - w_rock - w_mud, 0.0, 1.0);

	vec3 alb = texture(forest_albedo, uv).rgb * w_forest;
	alb += texture(mud_albedo, uv).rgb * w_mud;
	alb += texture(rock_albedo, uv).rgb * w_rock;
	alb += texture(snow_albedo, uv).rgb * w_snow;

	float macro = 0.5 + 0.5 * sin(wpos.x * 0.07) * cos(wpos.z * 0.055);
	alb *= mix(0.88, 1.12, macro);

	float wet = 1.0 - smoothstep(-1.4, 0.4, h);
	alb *= mix(1.0, 0.55, wet);

	ALBEDO = alb;
	ROUGHNESS = mix(0.95, 0.5, wet);
	METALLIC = 0.0;

	vec3 n0 = texture(forest_normal, uv).rgb * 2.0 - 1.0;
	vec3 n1 = texture(mud_normal, uv).rgb * 2.0 - 1.0;
	vec3 n2 = texture(rock_normal, uv).rgb * 2.0 - 1.0;
	vec3 n3 = texture(snow_normal, uv).rgb * 2.0 - 1.0;
	vec3 nm = n0 * w_forest + n1 * w_mud + n2 * w_rock + n3 * w_snow;
	if (dot(nm, nm) < 0.01) {
		nm = vec3(0.0, 0.0, 1.0);
	} else {
		nm = normalize(nm);
	}
	NORMAL_MAP = nm * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;
}
