shader_type canvas_item;

void fragment() {
    COLOR = texture(TEXTURE, UV);
    COLOR = vec4(0.0, 0.0, 0.0, 0.6);
    COLOR.rgb *= 0.8;  // Escurece a textura
}