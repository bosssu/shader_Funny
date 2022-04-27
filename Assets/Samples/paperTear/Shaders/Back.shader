Shader "Unlit/Back"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex ("Mask", 2D) = "white" {}
        _TotalMask("TotalMask",2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal:NORMAL;
                float4 wpos:TEXCOORD1;
            };

            sampler2D _MainTex,_MaskTex,_TotalMask;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = v.normal;
                o.wpos = mul(UNITY_MATRIX_V,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				// half lambert
                float3 worldNormal = normalize(UnityObjectToWorldNormal(i.normal));
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.wpos));
                float light = max(0,dot(worldNormal,lightDir)) * 0.5  + 0.5;

                fixed4 col = tex2D(_MainTex, i.uv);
                fixed alpha = tex2D(_MaskTex, i.uv).a;
                fixed totalMask = tex2D(_TotalMask, i.uv).r;
				// show the paper not was torn off
                if(alpha < 0.5)
                {
                    col.a = 0;
                }
                else if(alpha < 0.7)
                {
                    col = fixed4(1,1,1,0.8);
                }
                
                col.rgb *= light;
                col.a *= totalMask;
                return col;
            }
            ENDCG
        }
    }
}
