shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float corruption : hint_range(0.0, 1.0) = 0.0;
uniform float scan_strength : hint_range(0.0, 0.5) = 0.12;
uniform float vignette : hint_range(0.0, 1.0) = 0.5;

float rand(float x) { return fract(sin(x * 12.9898) * 43758.5453); }

void fragment() {
	float g = smoothstep(0.2, 1.0, corruption);   // до 20% коррупции — чисто

	vec2 uv = SCREEN_UV;

	// дрожание строк — мягкое, только при заметной коррупции
	float band = floor(uv.y * 40.0);
	float jitter = (rand(band + floor(TIME * 12.0)) - 0.5) * 0.018 * g;
	uv.x += jitter;

	// хром. аберрация: лёгкий постоянный CRT-фриндж + небольшой рост
	float ca = 0.0008 + 0.004 * g;
	float cr = texture(screen_tex, uv + vec2(ca, 0.0)).r;
	float cg = texture(screen_tex, uv).g;
	float cb = texture(screen_tex, uv - vec2(ca, 0.0)).b;
	vec3 col = vec3(cr, cg, cb);

	// скан-линии стабильны, чуть усиливаются
	float scan = mod(FRAGCOORD.y, 3.0) < 1.0 ? (scan_strength + 0.06 * g) : 0.0;
	col *= (1.0 - scan);

	// редкие ТОНКИЕ затемнения строк только у верхней коррупции (не чёрные полосы)
	float drop = step(0.985, rand(floor(uv.y * 120.0) + floor(TIME * 18.0))) * step(0.6, corruption);
	col = mix(col, col * 0.25, drop * g);

	// виньетка + лёгкий фликер
	col *= (1.0 - smoothstep(0.4, 0.85, length(SCREEN_UV - vec2(0.5))) * vignette);
	col *= 1.0 - (sin(TIME * 8.0) * 0.5 + 0.5) * 0.02;

	COLOR = vec4(col, 1.0);
}
