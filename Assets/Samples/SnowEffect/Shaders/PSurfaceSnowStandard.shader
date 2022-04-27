
Shader "PluginIdea/SurfaceSnowStandard" {
	Properties{
		_MainColor("Main Color", Color) = (0.5,0.5,0.5,1)
		_MainTex("Main Tex", 2D) = "white" {}
		_NormalTex("Normal Tex", 2D) = "bump" {}
		_SnowRampTex("Snow Toon Ramp Tex", 2D) = "gray" {}
		_SnowAngle("World Angle of snow grow", Vector) = (0,1,0)
		_SnowBaseColorTint("Snow Base Color", Color) = (0.5,0.5,0.5,1)
		_SnowTopColor("Snow Top Color", Color) = (1,1,1,1)
		_SnowSize("Snow Size", Range(0,1)) = 0.5
		_SnowOffset("Snow Height Offset", Range(0,0.2)) = 0.1
		_Gloss("Gloss",Range(0,1)) = 0.2
		_Metallic("Metallic",Range(0,1)) = 0

	}

	SubShader{
		Tags{ "RenderType" = "Opaque" }
		LOD 200
		Cull Off
		CGPROGRAM
		
		#pragma fragmentoption ARB_precision_hit_fastest
		#pragma surface surf Standard vertex:vert addshadow exclude_path:prepass

		sampler2D _MainTex;
		sampler2D _NormalTex;
		sampler2D _SnowRampTex;

		fixed4 _MainColor;
		fixed4 _SnowBaseColorTint;
		fixed4 _SnowTopColor;
		half4 _SnowAngle;
		half _Gloss;
		half _Metallic;

		half _SnowSize;
		half _SnowOffset;

		struct Input {
			half2 uv_MainTex : TEXCOORD0;
			float3 worldPos;
			half3 viewDir;
			half3 lightDir;
			half2 uv_NormalTex;
		};

		struct appdata {
			float4 vertex : POSITION;
			half3 normal : NORMAL;
		};

		void vert(inout appdata_full v, out Input o)
		{

			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.lightDir = WorldSpaceLightDir(v.vertex); 
			half4 snowAngleLocal = mul(_SnowAngle , unity_ObjectToWorld);
			// extruct along the local normal dirction
			v.vertex.xyz += snowAngleLocal * _SnowOffset * step(1 -_SnowSize,saturate(dot(normalize(v.normal), normalize(snowAngleLocal.xyz))));

		}

		void surf(Input IN, inout SurfaceOutputStandard o) {

			half4 ntex = tex2D(_NormalTex, IN.uv_NormalTex);
			half4 _SnowAngle_normalized = normalize(_SnowAngle);
			half4 mainColor = tex2D(_MainTex, IN.uv_MainTex) * _MainColor;

			half d = dot(o.Normal, IN.lightDir)*0.5 + 0.5; 
			fixed3 rampSnow = tex2D(_SnowRampTex, half2(d, d)).rgb; 

			o.Albedo = mainColor.rgb * _MainColor;


			half  stepvalue = step(1 -_SnowSize,saturate(dot(normalize(o.Normal+ ntex), _SnowAngle_normalized.xyz)));
			half lerrvalue = saturate(dot(IN.lightDir,_SnowAngle_normalized));
			o.Albedo = o.Albedo * (1 - stepvalue) + stepvalue * (lerp(_SnowBaseColorTint * rampSnow, _SnowTopColor * rampSnow, saturate(lerrvalue)));
			o.Alpha = mainColor.a;
			o.Smoothness = _Gloss;
			o.Metallic = _Metallic;
		}
		ENDCG

	}

	Fallback "Diffuse"
}