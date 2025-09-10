// Inspired by Krapas https://www.shadertoy.com/view/X3dGz2
#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uProgress; // 0.0 to 1.0, controls explosion progress

out vec4 fragColor;


// Hash-based 3D noise
vec3 n_rand3(vec3 p) {
    vec3 r = fract(sin(vec3(
        dot(p, vec3(127.1,311.7,371.8)),
        dot(p,vec3(269.5,183.3,456.1)),
        dot(p,vec3(352.5,207.3,198.67))
    )) * 43758.5453) * 2.0 - 1.0;
    return normalize(vec3(r.x/cos(r.x), r.y/cos(r.y), r.z/cos(r.z)));
}

float noise(vec3 p) {
    vec3 fv = fract(p);
    vec3 nv = floor(p);
    vec3 u = fv*fv*fv*(fv*(fv*6.0-15.0)+10.0);
    return (
        mix(
            mix(
                mix(
                    dot( n_rand3( nv+vec3(0.0,0.0,0.0) ), fv-vec3(0.0,0.0,0.0)),
                    dot( n_rand3( nv+vec3(1.0,0.0,0.0) ), fv-vec3(1.0,0.0,0.0)),
                    u.x
                ),
                mix(
                    dot( n_rand3( nv+vec3(0.0,1.0,0.0) ), fv-vec3(0.0,1.0,0.0)),
                    dot( n_rand3( nv+vec3(1.0,1.0,0.0) ), fv-vec3(1.0,1.0,0.0)),
                    u.x
                ),
                u.y
            ),
            mix(
                mix(
                    dot( n_rand3( nv+vec3(0.0,0.0,1.0) ), fv-vec3(0.0,0.0,1.0)),
                    dot( n_rand3( nv+vec3(1.0,0.0,1.0) ), fv-vec3(1.0,0.0,1.0)),
                    u.x
                ),
                mix(
                    dot( n_rand3( nv+vec3(0.0,1.0,1.0) ), fv-vec3(0.0,1.0,1.0)),
                    dot( n_rand3( nv+vec3(1.0,1.0,1.0) ), fv-vec3(1.0,1.0,1.0)),
                    u.x
                ),
                u.y
            ),
            u.z
       )
  );
}

float worley(vec3 s)
{
    vec3 si = floor(s);
    vec3 sf = fract(s);
    float m_dist = 1.;
    for (int y= -1; y <= 1; y++) {
        for (int x= -1; x <= 1; x++) {
            for (int z= -1; z <= 1; z++) {
                vec3 neighbor = vec3(float(x),float(y), float(z));
                vec3 point = fract(n_rand3(si + neighbor));
                point = 0.5 + 0.5*sin(uTime + 6.2831*point);
                vec3 diff = neighbor + point - sf;
                float dist = length(diff);
                m_dist = min(m_dist, dist);
            }
        }
    }
    return m_dist;
}

float oct_noise(vec3 pos, float o)
{
    float ns = 0.0;
    float d = 0.0;
    int io = int(o);
    float fo = fract(o);
    for(int i=0;i<=io;++i)
    {
        float v = pow(2.0,float(i));
        d += 1.0/v;
        ns += noise(pos*v)*(1.0/v);
    }
    float v = pow(2.0,float(io+1));
    d+= 1.0*fo/v;
    ns += noise(pos*v)*(1.0*fo/v);
    return ns/d;
}

float boom(vec2 p, float t)
{
    float repeat = t;
    float shape = 1.0 - pow(distance(vec3(p, 0.0), vec3(0.0)),2.0) / (repeat*12.0) - repeat*2.0;
    float distortion = noise(vec3(p*0.5, uTime*0.5));
    float bubbles = 0.5 - pow(worley(vec3(p*1.2,uTime*2.0)), 3.0);
    float bw = 0.5;
    float effects = (bw * bubbles + (1.0-bw) * distortion);
    return shape + effects;
}

float smoke(vec2 p, float t)
{
    float repeat = t;
    float shape = 1.0 - pow(distance(vec3(p + vec2(0, 2.0) * pow(repeat/1.45,2.0)*1.5, 0.0), vec3(0.0)),2.0) / (repeat*16.0) - pow(repeat*1.5,0.5);
    float distortion = noise(vec3(p*1.5 + vec2(0, 2.0) * pow(repeat/1.45,2.0)*1.5, uTime*0.1));
    float bubbles = 0.5 - pow(worley(vec3((p/pow(repeat,0.35)) + vec2(0, 2.0) * pow(repeat/1.65,2.0)*1.5, uTime*0.1)), 2.0);
    float bw = 0.75;
    float effects = (bw * bubbles + (1.0-bw) * distortion);
    return shape + effects;
}

float posterize(float v, float n)
{
    return floor(v*n)/(n-1.0);
}

void main() {
    vec3 boom_pal[4];
    boom_pal[0] = vec3(0.2, 0.15, 0.3);
    boom_pal[1] = vec3(0.9, 0.15, 0.05);
    boom_pal[2] = vec3(0.9, 0.5, 0.1);
    boom_pal[3] = vec3(0.95, 0.95, 0.35);
    vec3 smoke_pal[3];
    smoke_pal[0] = vec3(0.2, 0.15, 0.3);
    smoke_pal[1] = vec3(0.35, 0.3, 0.45);
    smoke_pal[2] = vec3(0.5, 0.45, 0.6);

    vec2 pos = FlutterFragCoord().xy;
    vec2 uv = pos / uSize;
    vec2 center = vec2(0.5, 0.4);
    vec2 p = uv - center;
    p.x *= uSize.x/uSize.y;
    p *= 7.0;
    float t = max(uProgress, 0.01);


    float bpl = 4.0;
    float spl = 3.0;

    float boom_val = boom(p, t);
    float boom_a = step(0.0, boom_val);
    int boom_idx = int(posterize(boom_val, bpl)*bpl);
    boom_idx = boom_idx < 0 ? 0 : (boom_idx > int(bpl)-1 ? int(bpl)-1 : boom_idx);
    vec3 boom_col = boom_pal[0];
    if (boom_idx == 1) boom_col = boom_pal[1];
    else if (boom_idx == 2) boom_col = boom_pal[2];
    else if (boom_idx == 3) boom_col = boom_pal[3];
    boom_col = boom_col - vec3(1.0-boom_a);

    float smoke_val = smoke(p, t);
    float smoke_a = step(0.0, smoke_val);
    int smoke_idx = int(posterize(smoke_val, spl)*spl);
    smoke_idx = smoke_idx < 0 ? 0 : (smoke_idx > int(spl)-1 ? int(spl)-1 : smoke_idx);
    vec3 smoke_col = smoke_pal[0];
    if (smoke_idx == 1) smoke_col = smoke_pal[1];
    else if (smoke_idx == 2) smoke_col = smoke_pal[2];
    smoke_col = smoke_col - vec3(1.0-smoke_a);

    float bw = step(smoke_val*1.25, boom_val);
    vec3 color = bw * boom_col + (1.0-bw) * smoke_col;
    float alpha = bw * boom_a + (1.0-bw) * smoke_a;

    // Soft fade at the bottom for ground effect
    float groundFade = smoothstep(0.18, 0.0, p.y/7.0);
    alpha *= groundFade;

    fragColor = vec4(color, alpha);
}
