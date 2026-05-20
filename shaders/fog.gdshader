shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.75, 0.85, 1.0, 1);

uniform float speed = 0.015;
uniform float scale = 2.5;

void fragment() {

    // movimento suave
    vec2 uv = UV;
    uv.x += TIME * speed;

    // noise base
    float noise = texture(TEXTURE, uv * scale).r;

    // deixa mais "fofo/redondo"
    noise = smoothstep(0.25, 0.8, noise);
	
    // fade vertical
    float bottom = smoothstep(0.0, 0.3, UV.y);
	float top = 1.0 - smoothstep(0.08, 0.22, UV.y);

	float vertical_fade = bottom * top;

	// fade lateral
    float side_fade = 1.0 - smoothstep(
        0.,
        0.5,
        abs(UV.x - 0.5)
    );

    // mistura final
    float fog = noise * vertical_fade * side_fade;

    COLOR.rgb = fog_color.rgb;
    COLOR.a = fog * fog_color.a;
}