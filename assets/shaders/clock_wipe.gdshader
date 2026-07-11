shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float aspect = 1.777;
uniform vec2 pixel_grid = vec2(160.0, 90.0);
uniform int mode = 0;

void fragment() {
	vec2 uv = floor(UV * pixel_grid) / pixel_grid;
	float covered;
	if (mode == 0) {
		vec2 p = uv - vec2(0.5);
		p.x *= aspect;
		float angle = atan(p.x, -p.y);
		angle = angle < 0.0 ? angle + TAU : angle;
		covered = step(angle, progress * TAU);
	} else {
		covered = step(uv.y, progress);
	}
	covered *= step(0.0001, progress);
	COLOR = vec4(wipe_color.rgb, wipe_color.a * covered);
}
