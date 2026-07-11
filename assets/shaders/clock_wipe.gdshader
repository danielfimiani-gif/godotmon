shader_type canvas_item;
// Barrido de reloj PIXELADO: pinta un sector circular que crece con `progress` (0→1).
// Cada píxel se pinta si su ángulo respecto al centro ya entró en el sector barrido.
// El UV se cuantiza a una grilla baja → el borde queda escalonado, coherente con el pixel art.
// Nota: TAU, PI y E ya son constantes incorporadas del shader de Godot (no redeclarar).

uniform float progress : hint_range(0.0, 1.0) = 0.0;   // 0 = nada tapado, 1 = todo tapado
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);  // color del velo
uniform float aspect = 1.777;                          // ancho/alto, para que el barrido sea redondo
uniform vec2 pixel_grid = vec2(160.0, 90.0);           // resolución del pixelado (más chico = píxeles más gordos)

void fragment() {
	vec2 uv = floor(UV * pixel_grid) / pixel_grid;   // pixelar el UV a la grilla baja
	vec2 p = uv - vec2(0.5);
	p.x *= aspect;                                   // corregir la relación de aspecto
	float angle = atan(p.x, -p.y);                   // 0 = arriba (12 en punto), sentido horario
	angle = angle < 0.0 ? angle + TAU : angle;
	float covered = step(angle, progress * TAU);     // dentro del sector barrido → 1
	COLOR = vec4(wipe_color.rgb, wipe_color.a * covered);
}
