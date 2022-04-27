
Shader "SnowNormalSurface" {
	Properties{
		_MainColor("Main Color", Color) = (0.5,0.5,0.5,1)
		_MainTex("Main Tex", 2D) = "white" {}
		_NormalTex("Normal Tex", 2D) = "bump" {}
		_SnowAngle("World Angle of snow grow", Vector) = (0,1,0)
		_SnowBaseColorTint("Snow Base Color", Color) = (0.5,0.5,0.5,1)
		_SnowTopColor("Snow Top Color", Color) = (1,1,1,1)
		_SnowSize("Snow Size", Range(0,1)) = 0.5
		_SnowOffset("Snow Height Offset", Range(0,0.2)) = 0.1


	}

	SubShader{
		Tags{ "RenderType" = "Opaque" }
		LOD 200
		Cull Off
		CGPROGRAM

		#pragma fragmentoption ARB_precision_hit_fastest
		#pragma surface surf Lambert vertex:vert addshadow exclude_path:prepass

		sampler2D _MainTex;
		sampler2D _NormalTex;

		fixed4 _MainColor;
		fixed4 _SnowBaseColorTint;
		fixed4 _SnowTopColor;
		half3 _SnowAngle;

		half _SnowSize;
		half _SnowOffset;

		struct Input {
			half2 uv_MainTex : TEXCOORD0;
			half2 uv_NormalTex;
			float3 worldNormal;
			INTERNAL_DATA
		};

		struct appdata {
			float4 vertex : POSITION;
			half3 normal : NORMAL;
			half3 worldNormal;
		};

		void vert(inout appdata_full v, out Input o)
		{

			UNITY_INITIALIZE_OUTPUT(Input, o);
			half3 worldNormal = UnityObjectToWorldNormal(v.normal);
			v.vertex.xyz += v.normal * _SnowOffset * saturate(dot(worldNormal,normalize(_SnowAngle)));

		}

		void surf(Input IN, inout SurfaceOutput o) {

			half3 _SnowAngle_normalized = normalize(_SnowAngle);
			float s = saturate(dot(_SnowAngle_normalized,IN.worldNormal));
			s = smoothstep(0,1 - _SnowSize,s);
			half3 snowColor = lerp(_SnowBaseColorTint,_SnowTopColor,s);
			half4 mainColor = tex2D(_MainTex, IN.uv_MainTex) * _MainColor;
			mainColor.rgb = lerp(mainColor.rgb,snowColor,s);

			o.Albedo = mainColor.rgb * _MainColor;

		}
		ENDCG

	}

	Fallback "Diffuse"

}