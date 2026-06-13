shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float corruption : hint_range(0.0, 1.0) = 0.0;
uniform float scan_strength : hint_range(0.0, 0.5) = 0.12;
uniform float vignette : hint_range(0.0, 1.0) = 0.5;

float rand(float x) { return fract(sin(x * 12.9898) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;

	// дрожание строк, усиливается с коррупцией
	float band = floor(uv.y * 40.0);
	float jitter = (rand(band + floor(TIME * 12.0)) - 0.5) * 0.06 * corruption;
	uv.x += jitter;

	// хроматическая аберрация
	float ca = 0.0015 + 0.012 * corruption;
	float r = texture(screen_tex, uv + vec2(ca, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - vec2(ca, 0.0)).b;
	vec3 col = vec3(r, g, b);

	// скан-линии
	float scan = mod(FRAGCOORD.y, 3.0) < 1.0 ? (scan_strength + 0.15 * corruption) : 0.0;
	col *= (1.0 - scan);

	// редкие выпадения строк при высокой коррупции
	float drop = step(0.995 - 0.03 * corruption, rand(floor(uv.y * 120.0) + floor(TIME * 20.0)));
	col = mix(col, vec3(0.0), drop * corruption);

	// виньетка + лёгкий фликер
	col *= (1.0 - smoothstep(0.4, 0.85, length(SCREEN_UV - vec2(0.5))) * vignette);
	col *= 1.0 - (sin(TIME * 8.0) * 0.5 + 0.5) * 0.02;

	COLOR = vec4(col, 1.0);
}
