shader_type canvas_item;

uniform vec4 amber : source_color = vec4(1.0, 0.69, 0.0, 1.0);
uniform vec4 amber_dim : source_color = vec4(0.72, 0.49, 0.07, 1.0);

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	float ang = atan(p.y, p.x);
	float bands = 0.5 + 0.5 * sin(ang * 4.0 - TIME * 0.6);        // вращающиеся сектора
	float ring = smoothstep(0.50, 0.46, r) * smoothstep(0.30, 0.34, r);
	float core = smoothstep(0.22, 0.0, r) * (0.85 + 0.15 * sin(TIME * 2.4)); // пульс ядра
	vec3 col = mix(amber_dim.rgb, amber.rgb, bands) * ring + amber.rgb * core;
	COLOR = vec4(col, clamp(ring + core, 0.0, 1.0));
}
