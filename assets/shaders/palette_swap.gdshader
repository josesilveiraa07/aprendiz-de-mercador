shader_type canvas_item;
// Troca de paleta do sprite "Customer" do pacote CraftPix.
// Permite criar clientes visualmente distintos (cabelo, capa e camisa)
// reaproveitando a mesma spritesheet, sem desenhar arte nova.
// Cada uniforme é (matiz 0..1, multiplicador de saturação, multiplicador de brilho).

uniform vec3 hair = vec3(-1.0, 1.0, 1.0);
uniform vec3 cloak = vec3(-1.0, 1.0, 1.0);
uniform vec3 shirt = vec3(-1.0, 1.0, 1.0);

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 recolor(vec3 hsv, vec3 target) {
	return hsv2rgb(vec3(target.x, clamp(hsv.y * target.y, 0.0, 1.0), clamp(hsv.z * target.z, 0.0, 1.0)));
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec3 hsv = rgb2hsv(col.rgb);
	bool is_hair = hsv.y >= 0.6 && (hsv.x < 0.09 || hsv.x > 0.97) && hsv.z > 0.28;
	bool is_cloak = hsv.x > 0.55 && hsv.x < 0.72 && hsv.y > 0.15 && hsv.z > 0.12;
	bool is_shirt = hsv.x > 0.15 && hsv.x < 0.35 && hsv.y > 0.4;
	if (is_hair && hair.x >= 0.0) {
		col.rgb = recolor(hsv, hair);
	} else if (is_cloak && cloak.x >= 0.0) {
		col.rgb = recolor(hsv, cloak);
	} else if (is_shirt && shirt.x >= 0.0) {
		col.rgb = recolor(hsv, shirt);
	}
	COLOR = col * vertex_color;
}
