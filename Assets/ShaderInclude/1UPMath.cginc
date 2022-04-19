#ifndef ONEUP_MATH_CG_INCLUDE
    #define ONEUP_MATH_CG_INCLUDE

    inline fixed3 HSV2RGB(fixed3 _in)
    {
        return float3(lerp(float3(1,1,1),saturate(3.0*abs(1.0-2.0*frac(_in.x+float3(0.0,-1.0/3.0,1.0/3.0)))-1),_in.y)*_in.z);
    } 

    inline fixed4 RGB2HSV(fixed4 _in)
    {
        float4 k = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = lerp(float4(_in.zy, k.wz), float4(_in.yz, k.xy), step(_in.z, _in.y));
        float4 q = lerp(float4(p.xyw, _in.x), float4(_in.x, p.yzx), step(p.x, _in.x));
        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return float4(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x, 0);
    }

    inline fixed Noise1(float2 uv)
    {
        float2 _xy = uv;
        float2 s = _xy + 0.2127+_xy.x*0.3713*_xy.y;
        float2 r = 4.789*sin(489.123*s);
        return frac(r.x*r.y*(1+s.x));
    }

    inline float Remap(float _imin, float _imax, float _omin, float _omax, float _in)
    {
        return _omin + ( (_in - _imin) * (_omax - _omin) ) / (_imax - _imin);
    }

    //a向量在b向量上的投影向量
    inline float3 VectorProj(float3 _a,float3 _b)
    {
        return _b * dot(_a,_b)/dot(_b,_b);
    }

    //灰度值
    inline float GetGrayValue(fixed3 col)
    {
        return 0.299*col.r + 0.587*col.g + 0.184*col.b;
    }

    float2 hash22(float2 p) 
    {
        p = float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3)));
        return -1.0 + 2.0*frac(sin(p)*43758.5453123);
    }

    float2 hash21(float2 p) {
        float h=dot(p,float2(127.1,311.7));
        return -1.0 + 2.0*frac(sin(h)*43758.5453123);
    }

    //矩阵-----------------------------------------------------------------------------

    #define MATRIX_2(angle) \
    float2x2( \
    cos(angle),-sin(angle), \
    sin(angle),cos(angle) \
    )

    #define MATRIX_3_X(angle) \
    float3x3( \
    1,0,0, \
    0,cos(angle),-sin(angle), \
    0,sin(angle),cos(angle) \
    )

    #define MATRIX_3_Y(angle) \
    float3x3( \
    cos(angle),0,sin(angle), \
    0,1,0, \
    -sin(angle),0,cos(angle) \
    )

    #define MATRIX_3_Z(angle) \
    float3x3( \
    cos(angle),-sin(angle),0, \
    sin(angle,cos(angle),0) \
    0,0,1 \
    )

    //绕y轴旋转特定角度(弧度)
    float4 RotateAroundYInDegrees(float4 vertex, float degrees)
    {
        float sina, cosa;
        sincos(degrees, sina, cosa);
        float2x2 m = float2x2(cosa, -sina, sina, cosa);
        return float4(mul(m, vertex.xz), vertex.yw).xzyw;
    }

    //绕某条轴旋转特定角度(弧度)
    float3x3 AngleAxis3x3(float angle, float3 axis)
    {
        float c, s;
        sincos(angle, s, c);

        float t = 1 - c;
        float x = axis.x;
        float y = axis.y;
        float z = axis.z;

        return float3x3(
        t * x * x + c, t * x * y - s * z, t * x * z + s * y,
        t * x * y + s * z, t * y * y + c, t * y * z - s * x,
        t * x * z - s * y, t * y * z + s * x, t * z * z + c
        );
    }

    //噪声-----------------------------------------------------------------------------
    //perlin
    float perlin_noise(float2 p) {				
        float2 pi = floor(p);
        float2 pf = p - pi;
        float2 w = pf * pf*(3.0 - 2.0*pf);
        return lerp(lerp(dot(hash22(pi + float2(0.0, 0.0)), pf - float2(0.0, 0.0)),
        dot(hash22(pi + float2(1.0, 0.0)), pf - float2(1.0, 0.0)), w.x),
        lerp(dot(hash22(pi + float2(0.0, 1.0)), pf - float2(0.0, 1.0)),
        dot(hash22(pi + float2(1.0, 1.0)), pf - float2(1.0, 1.0)), w.x), w.y);
    }

    //value
    float value_noise(float2 p) {
        float2 pi = floor(p);
        float2 pf = p - pi;
        float2 w = pf * pf*(3.0 - 2.0*pf);
        return lerp(lerp(hash21(pi+float2(0.0, 0.0)), hash21(pi + float2(1.0, 0.0)), w.x),
        lerp(hash21(pi + float2(0.0, 1.0)), hash21(pi + float2(1.0, 1.0)), w.x), w.y);
    }

    //simplex
    float simplex_noise(float2 p) {
        float k1 = 0.366025404;
        float k2 = 0.211324865;
        float2 i = floor(p + (p.x + p.y)*k1);
        float2 a = p - (i - (i.x + i.y)*k2);
        float2 o = (a.x < a.y) ? float2(0.0, 1.0) : float2(1.0, 0.0);
        float2 b = a - o + k2;
        float2 c = a - 1.0 + 2.0*k2;
        float3 h = max(0.5 - float3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
        float3 n = h * h*h*h*float3(dot(a, hash22(i)), dot(b, hash22(i + o)), dot(c, hash22(i + 1.0)));
        return dot(float3(70.0, 70.0, 70.0), n);
    }

    //fbm分形叠加
    float noise_sum(float2 p) {
        float f = 0.0;
        p = p * 4.0;
        f += 1.0*perlin_noise(p);
        p = 2.0*p;
        f += 0.5*perlin_noise(p);
        p = 2.0*p;
        f += 0.25*perlin_noise(p);
        p = 2.0*p;
        f += 0.125*perlin_noise(p);
        p = 2.0*p;
        f += 0.0625*perlin_noise(p);
        return f;
    }

    float noise_sum_value(float2 p) {
        float f = 0.0;
        p = p * 4.0;
        f += 1.0*value_noise(p);
        p = 2.0*p;
        f += 0.5*value_noise(p);
        p = 2.0*p;
        f += 0.25*value_noise(p);
        p = 2.0*p;
        f += 0.125*value_noise(p);
        p = 2.0*p;
        f += 0.0625*value_noise(p);
        return f;
    }

    float noise_sum_simplex(float2 p) {
        float f = 0.0;
        p = p * 4.0;
        f += 1.0*simplex_noise(p);
        p = 2.0*p;
        f += 0.5*simplex_noise(p);
        p = 2.0*p;
        f += 0.25*simplex_noise(p);
        p = 2.0*p;
        f += 0.125*simplex_noise(p);
        p = 2.0*p;
        f += 0.0625*simplex_noise(p);
        return f;
    }

    //turbulence
    float noise_sum_abs(float2 p) {
        float f = 0.0;
        p = p * 7.0;
        f += 1.0*abs(perlin_noise(p));
        p = 2.0*p;
        f += 0.5*abs(perlin_noise(p));
        p = 2.0*p;
        f += 0.25*abs(perlin_noise(p));
        p = 2.0*p;
        f += 0.125*abs(perlin_noise(p));
        p = 2.0*p;
        f += 0.0625*abs(perlin_noise(p));
        return f;
    }

    float noise_sum_abs_value(float2 p) {
        float f = 0.0;
        p = p * 7.0;
        f += 1.0*abs(value_noise(p));
        p = 2.0*p;
        f += 0.5*abs(value_noise(p));
        p = 2.0*p;
        f += 0.25*abs(value_noise(p));
        p = 2.0*p;
        f += 0.125*abs(value_noise(p));
        p = 2.0*p;
        f += 0.0625*abs(value_noise(p));
        return f;
    }

    float noise_sum_abs_simplex(float2 p) {
        float f = 0.0;
        p = p * 7.0;
        f += 1.0*abs(simplex_noise(p));
        p = 2.0*p;
        f += 0.5*abs(simplex_noise(p));
        p = 2.0*p;
        f += 0.25*abs(simplex_noise(p));
        p = 2.0*p;
        f += 0.125*abs(simplex_noise(p));
        p = 2.0*p;
        f += 0.0625*abs(simplex_noise(p));
        return f;
    }

    //turbulence_sin
    float noise_sum_abs_sin(float2 p) {
        float f = 0.0;
        p = p * 16.0;
        f += 1.0*abs(perlin_noise(p));
        p = 2.0*p;
        f += 0.5*abs(perlin_noise(p));
        p = 2.0*p;
        f += 0.25*abs(perlin_noise(p));
        p = 2.0*p;
        f += 0.125*abs(perlin_noise(p));
        p = 2.0*p;
        f += 0.0625*abs(perlin_noise(p));
        p = 2.0*p;
        f = sin(f + p.x / 32.0);
        return f;
    }

    float noise_sum_abs_sin_value(float2 p) {
        float f = 0.0;
        p = p * 16.0;
        f += 1.0*abs(value_noise(p));
        p = 2.0*p;
        f += 0.5*abs(value_noise(p));
        p = 2.0*p;
        f += 0.25*abs(value_noise(p));
        p = 2.0*p;
        f += 0.125*abs(value_noise(p));
        p = 2.0*p;
        f += 0.0625*abs(value_noise(p));
        p = 2.0*p;
        f = sin(f + p.x / 32.0);
        return f;
    }

    float noise_sum_abs_sin_simplex(float2 p) {
        float f = 0.0;
        p = p * 16.0;
        f += 1.0*abs(simplex_noise(p));
        p = 2.0*p;
        f += 0.5*abs(simplex_noise(p));
        p = 2.0*p;
        f += 0.25*abs(simplex_noise(p));
        p = 2.0*p;
        f += 0.125*abs(simplex_noise(p));
        p = 2.0*p;
        f += 0.0625*abs(simplex_noise(p));
        p = 2.0*p;
        f = sin(f + p.x / 32.0);
        return f;
    }

    float rand(float3 co)
    {
        return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
    }


#endif