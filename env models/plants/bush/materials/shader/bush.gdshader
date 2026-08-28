shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled,
diffuse_burley, specular_schlick_ggx, depth_prepass_alpha;

// ============================================================
// MATERIAL
// ============================================================

uniform vec4 albedo : source_color = vec4(1.0);

uniform sampler2D texture_albedo :
source_color,
filter_linear_mipmap,
repeat_enable;

uniform float roughness : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D texture_metallic :
hint_default_white,
filter_linear_mipmap,
repeat_enable;

uniform vec4 metallic_texture_channel =
vec4(1.0, 0.0, 0.0, 0.0);

uniform sampler2D texture_roughness :
hint_roughness_r,
filter_linear_mipmap,
repeat_enable;

uniform float metallic : hint_range(0.0, 1.0) = 0.0;

uniform float specular : hint_range(0.0, 1.0) = 0.13;


// ============================================================
// NORMAL
// ============================================================

uniform sampler2D texture_normal :
hint_roughness_normal,
filter_linear_mipmap,
repeat_enable;

uniform float normal_scale :
hint_range(-16.0, 16.0) = 1.5;


// ============================================================
// AO
// ============================================================

uniform sampler2D texture_ao :
hint_default_white,
filter_linear_mipmap,
repeat_enable;

uniform float ao_strength :
hint_range(0.0, 1.0) = 1.0;


// ============================================================
// BACKLIGHT
// ============================================================

uniform vec3 backlight : source_color = vec3(0.0);

uniform sampler2D texture_backlight :
hint_default_black,
filter_linear_mipmap,
repeat_enable;


// ============================================================
// UV
// ============================================================

uniform vec2 uv_scale = vec2(1.0);

uniform vec2 uv_offset = vec2(0.0);


// ============================================================
// LOCAL WIND
// ============================================================
//
// These are LOCAL uniforms.
//
// Every material can have its own:
//
// wind_speed
// wind_strength
// wind_frequency
// wind_detail
// wind_direction
//
// ============================================================

uniform float wind_speed = 1.0;

uniform float wind_strength :
hint_range(0.0, 5.0) = 1.0;

uniform float wind_frequency :
hint_range(0.0, 10.0) = 1.0;

uniform float wind_detail :
hint_range(0.0, 2.0) = 0.3;

uniform vec2 wind_direction = vec2(1.0, 0.0);


// ============================================================
// LOCAL VEGETATION SETTINGS
// ============================================================

// 0.0 = ignore vertex colors
// 1.0 = use COLOR.r as the wind mask

uniform float vertex_mask_strength :
hint_range(0.0, 1.0) = 1.0;


// Controls how strongly the individual vertex movement
// follows the wind direction.

uniform float directional_strength :
hint_range(0.0, 1.0) = 0.5;


// ============================================================
// VERTEX
// ============================================================

void vertex() {

    // --------------------------------------------------------
    // Vertex position
    // --------------------------------------------------------

    vec3 pos = VERTEX;


    // --------------------------------------------------------
    // VERTEX COLOR WIND MASK
    // --------------------------------------------------------

    float color_mask = COLOR.r;

    float wind_mask = mix(
        1.0,
        color_mask,
        vertex_mask_strength
    );


    // --------------------------------------------------------
    // TIME
    // --------------------------------------------------------

    float time = TIME * wind_speed;


    // --------------------------------------------------------
    // POSITION
    // --------------------------------------------------------

    float x = pos.x;
    float y = pos.y;
    float z = pos.z;


    // --------------------------------------------------------
    // MAIN WIND WAVES
    // --------------------------------------------------------

    float wave_x = sin(
        x * wind_frequency * 1.123
        + time
        + z * 0.37
    );


    float wave_y = sin(
        y * wind_frequency
        + time * 1.12412
        + x * 0.23
    );


    float wave_z = sin(
        z * wind_frequency * 0.9123
        + time * 1.3123
        + x * 0.31
    );


    // --------------------------------------------------------
    // SECONDARY WAVES
    // --------------------------------------------------------

    float detail_x = sin(
        x * wind_frequency * 2.13
        + z * 1.73
        + time * 1.71
    );


    float detail_y = sin(
        y * wind_frequency * 1.71
        + x * 1.37
        + time * 1.37
    );


    float detail_z = cos(
        z * wind_frequency * 2.41
        + x * 1.53
        + time * 1.19
    );


    // --------------------------------------------------------
    // COMBINE MAIN + DETAIL
    // --------------------------------------------------------

    float final_x =
        wave_x
        + detail_x * wind_detail;


    float final_y =
        wave_y
        + detail_y * wind_detail;


    float final_z =
        wave_z
        + detail_z * wind_detail;


    // --------------------------------------------------------
    // WIND DIRECTION
    // --------------------------------------------------------

    vec2 direction = normalize(wind_direction);

    float directional_wave = sin(
        x * 0.41
        + z * 0.37
        + y * wind_frequency
        + time
    );


    // --------------------------------------------------------
    // DIRECTIONAL MOVEMENT
    // --------------------------------------------------------

    final_x +=
        directional_wave
        * direction.x
        * directional_strength;


    final_z +=
        directional_wave
        * direction.y
        * directional_strength;


    // --------------------------------------------------------
    // APPLY WIND
    // --------------------------------------------------------

    pos.x +=
        final_x
        * wind_strength
        * wind_mask;


    pos.y +=
        final_y
        * wind_strength
        * 0.25
        * wind_mask;


    pos.z +=
        final_z
        * wind_strength
        * wind_mask;


    // --------------------------------------------------------
    // APPLY POSITION
    // --------------------------------------------------------

    VERTEX = pos;


    // --------------------------------------------------------
    // UV
    // --------------------------------------------------------

    UV = UV * uv_scale + uv_offset;
}


// ============================================================
// FRAGMENT
// ============================================================

void fragment() {

    vec2 base_uv = UV;


    // ========================================================
    // ALBEDO
    // ========================================================

    vec4 albedo_tex = texture(
        texture_albedo,
        base_uv
    );

    ALBEDO =
        albedo.rgb *
        albedo_tex.rgb;


    // ========================================================
    // METALLIC
    // ========================================================

    float metallic_tex = dot(
        texture(texture_metallic, base_uv),
        metallic_texture_channel
    );

    METALLIC =
        metallic_tex *
        metallic;


    // ========================================================
    // ROUGHNESS
    // ========================================================

    float roughness_tex = texture(
        texture_roughness,
        base_uv
    ).r;

    ROUGHNESS =
        roughness_tex *
        roughness;


    // ========================================================
    // SPECULAR
    // ========================================================

    SPECULAR = specular;


    // ========================================================
    // NORMAL
    // ========================================================

    NORMAL_MAP = texture(
        texture_normal,
        base_uv
    ).rgb;

    NORMAL_MAP_DEPTH = normal_scale;


    // ========================================================
    // AO
    // ========================================================

    float ao_tex = texture(
        texture_ao,
        base_uv
    ).r;

    AO = mix(
        1.0,
        ao_tex,
        ao_strength
    );


    // ========================================================
    // ALPHA
    // ========================================================

    ALPHA =
        albedo.a *
        albedo_tex.a;


    // ========================================================
    // BACKLIGHT
    // ========================================================

    vec3 backlight_tex = texture(
        texture_backlight,
        base_uv
    ).rgb;

    BACKLIGHT =
        backlight +
        backlight_tex;
}