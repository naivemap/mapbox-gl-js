attribute highp vec4 a_pos_end;
attribute highp float a_angular_offset_factor;
attribute highp float a_hidden_by_landmark;

#ifdef SDF_SUBPASS
varying highp vec2 v_pos;
varying highp vec4 v_line_segment;
varying highp float v_flood_light_radius_tile;
varying highp vec2 v_ao;
#ifdef FOG
varying highp float v_fog;
#endif
#endif

uniform highp float u_flood_light_intensity;

uniform highp mat4 u_matrix;
uniform highp float u_ao_pass;
uniform highp float u_meter_to_tile;
uniform highp float u_edge_radius; // in tile coords

uniform highp vec2 u_ao;

#pragma mapbox: define highp float flood_light_ground_radius
#pragma mapbox: define highp float base

const float TANGENT_CUTOFF = 4.0;

void main() {
    #pragma mapbox: initialize highp float flood_light_ground_radius
    #pragma mapbox: initialize highp float base

    vec2 p = a_pos_end.xy;
    vec2 q = floor(a_pos_end.zw * 0.5);
    vec2 start_bottom = a_pos_end.zw - q * 2.0;

    float flood_radius_tile = flood_light_ground_radius * u_meter_to_tile;
    vec2 v = normalize(q - p);
    float ao_radius = u_ao.y / 3.5; // adjust AO radius slightly
    float effect_radius = mix(flood_radius_tile, ao_radius, u_ao_pass) + u_edge_radius;

    float angular_offset_factor = a_angular_offset_factor / EXTENT * TANGENT_CUTOFF;
    float angular_offset = angular_offset_factor * effect_radius;

    float top = 1.0 - start_bottom.y;

    float side = (0.5 - start_bottom.x) * 2.0;
    vec2 extrusion_parallel = v * side * mix(effect_radius / 10.0, angular_offset, top);

    vec2 perp = vec2(v.y, -v.x);
    vec2 extrusion_perp = perp * effect_radius * top;

    vec3 pos = vec3(mix(q, p, start_bottom.x), 0.0);
    pos.xy += extrusion_parallel + extrusion_perp;

#ifdef SDF_SUBPASS
    v_pos = pos.xy;
    // Shift the line segment against which we compute the signed distance values. 
    // This allows us to achieve pleasant results without having to add additional
    // vertices when fill-extrusion-edge-radius is non-zero. 
    v_line_segment = vec4(p, q) + perp.xyxy * u_edge_radius;
    v_flood_light_radius_tile = flood_radius_tile;
    v_ao = vec2(u_ao.x, ao_radius);
#ifdef FOG
    v_fog = 1.0 - fog(fog_position(pos));
#endif
#endif

    float hidden_by_landmark = 0.0;
#ifdef HAS_CENTROID
    hidden_by_landmark = a_hidden_by_landmark;
#endif

    float isFloodlit = float(flood_light_ground_radius > 0.0 && u_flood_light_intensity > 0.0);
    float hidden = mix(1.0 - isFloodlit, isFloodlit, u_ao_pass);
    hidden += float(base > 0.0); // vertex base is above ground.
    hidden += hidden_by_landmark;

    gl_Position = mix(u_matrix * vec4(pos, 1.0), AWAY, float(hidden > 0.0));
}