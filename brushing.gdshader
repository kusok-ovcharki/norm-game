// mask_blend.gdshader
shader_type canvas_item;

uniform sampler2D normal_tex;
uniform sampler2D hover_tex;
uniform sampler2D mask_tex;

void fragment() {
    vec4 normal = texture(normal_tex, UV);
    vec4 hover = texture(hover_tex, UV);
    float mask = texture(mask_tex, UV).r;

    COLOR = mix(normal, hover, mask);
}