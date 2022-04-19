Shader "Water/VotexExtendPurePlus"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        [Normal]_NormalTex ("Normal", 2D) = "white" {}
        _FoamTex("FoamTex",2D) = "white"{}
        _FoamStrengh("FoamStrengh",Range(0,1)) = 0.2
        _XSpeed("XSpeed",Range(0,1)) = 0.2
        _YSpeed("YSpeed",Range(0,1)) = 0.2
        _Gloss("Gloss",Range(0,0.1)) = 0.1
        _SpecStrengh("SpecStrengh",Range(0,0.01)) = 1
        _RefractionAmount("RefractAmount",Range(0,100)) = 5
        _TessellateAmount("TessellateAmount",float) = 4

        _Votex_Para("Votex_Para",vector) = (0.5,0.5,0.2,0)  //x,y:vortex center  z:vortex radius
        _Votex_Para1("Votex_Para1",vector) = (0.5,0.5,3,0)//x,y:At the bottom of the vortex  z:vortex's depth
        _Votex_distortAmount("Votex_distortAmount",Range(0,20)) = 2 
        _Shape_distortAmount("Shape_distortAmount",Range(0,1)) = 0.5

    }

    CGINCLUDE
    
    #include "Assets/ShaderInclude/1UPUtility.cginc"
    #include "Assets/ShaderInclude/1UPMath.cginc"

    sampler2D _NormalTex,_FoamTex;
    half4 _NormalTex_ST,_FoamTex_ST;
    float _XSpeed,_YSpeed,_Gloss,_SpecStrengh,_TessellateAmount,_FoamStrengh;
    fixed4 _BaseColor,_Votex_Para,_Votex_Para1;
    float _Votex_distortAmount,_Shape_distortAmount,_RefractionAmount;
    sampler2D _GrabTexture;
    float4 _GrabTexture_TexelSize;

    
    struct v2f
    {
        float4 uv : TEXCOORD0;
        UNITY_FOG_COORDS(1)
        float4 vertex : SV_POSITION;
        float3 normal:NORMAL;
        float4 screenPos:TEXCOORD2;
        float4 localPosition:TEXCOORD3;
    };

    v2f vert (appdata_base v)
    {
        v2f o;

        float3 center = float3(_Votex_Para.x,0,_Votex_Para.y);
        float3 bottomCenter = float3(_Votex_Para1.x,_Votex_Para1.z,_Votex_Para1.y);
        float3 mainVec = bottomCenter - center;
        float radius = _Votex_Para.z;
        float dis = distance(v.vertex.xyz,center);
        float s = saturate((radius - dis)) / radius;
        float ss = s * s;
		//The closer you get to the center of the vortex, the greater the vertex offset. Ss = s* S, which creates an arc of vortices
        float offsetN = _Votex_Para1.z * ss;
        
		//set the vertex's offset
        v.vertex.xyz = v.vertex.xyz - v.normal * offsetN;
        v.vertex.xyz = lerp(v.vertex.xyz,bottomCenter,offsetN / _Votex_Para1.z);

        //the matrix of rotate around a axis
        float3 mainDir = normalize(mainVec);
        float3x3 matrix_MainVec= AngleAxis3x3(abs( v.vertex.y * _Votex_distortAmount),mainDir);

        o.uv.xy = v.texcoord.xy * _NormalTex_ST.xy + _NormalTex_ST.zw;
        o.uv.zw = v.texcoord.xy * _FoamTex_ST.xy + _FoamTex_ST.zw;
        o.localPosition = v.vertex;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.normal = v.normal;
        o.screenPos = ComputeGrabScreenPos(o.vertex);

        return o;

    }

    fixed4 frag (v2f i) : SV_Target
    {
        fixed4 mainColor = _BaseColor;
        float4 worldPosition = mul(unity_ObjectToWorld,i.localPosition);

        float3 n1 = UnpackNormal(tex2D(_NormalTex,i.uv.xy + float2(_XSpeed,_YSpeed) * 0.1 * _Time.y));
        float3 n2 = UnpackNormal(tex2D(_NormalTex,i.uv.xy - float2(_XSpeed,_YSpeed) * 0.1 * _Time.y));
        float3 offset = BlendNormalRNM(n1,n2);

		//foam
        fixed4 foamColor = tex2D(_FoamTex,i.uv.zw);
        mainColor += foamColor * _FoamStrengh;

		//transparent
        i.screenPos.xy /= i.screenPos.w;
		//Refraction (increased refraction at vortex)
        i.screenPos.xy += offset.xy * (_RefractionAmount + abs(i.localPosition.y) * 400) * _GrabTexture_TexelSize.xy;
        fixed4 backColor = tex2D(_GrabTexture,i.screenPos.xy);
        mainColor *= backColor;

		//Lighting (there is no normal in the highlight part, just add the following randomly, lazy)
        half3 worldViewDir = normalize(WorldSpaceViewDir(worldPosition));
        half3 worldLightDir = normalize(WorldSpaceLightDir(worldPosition));
        half3 objectWorldNormal = UnityObjectToWorldNormal(i.normal);
        half3 specular = Highlights(worldPosition.xyz,_Gloss,normalize(objectWorldNormal - offset),worldViewDir,worldLightDir);
        mainColor.rgb += specular * _SpecStrengh * (0.05 + abs(i.localPosition.y) * 400);

        // mainColor.rgb = specular;
        return mainColor;
    }

    // tessellation vertex shader
    struct InternalTessInterp_appdata_base {
        float4 vertex : INTERNALTESSPOS;
        float3 normal : NORMAL;
        float4 texcoord : TEXCOORD0;
    };
    InternalTessInterp_appdata_base tessvert_surf (appdata_base v) {
        InternalTessInterp_appdata_base o;
        o.vertex = v.vertex;
        o.normal = v.normal;
        o.texcoord = v.texcoord;
        return o;
    }

    // tessellation hull constant shader
    UnityTessellationFactors hsconst_surf (InputPatch<InternalTessInterp_appdata_base,3> v) {
        UnityTessellationFactors o;
        float4 tf;
        tf = _TessellateAmount;
        o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
        return o;
    }

    // tessellation hull shader
    [UNITY_domain("tri")]
    [UNITY_partitioning("fractional_odd")]
    [UNITY_outputtopology("triangle_cw")]
    [UNITY_patchconstantfunc("hsconst_surf")]
    [UNITY_outputcontrolpoints(3)]
    InternalTessInterp_appdata_base hs_surf (InputPatch<InternalTessInterp_appdata_base,3> v, uint id : SV_OutputControlPointID) {
        return v[id];
    }

    // tessellation domain shader
    [UNITY_domain("tri")]
    v2f ds_surf (UnityTessellationFactors tessFactors, const OutputPatch<InternalTessInterp_appdata_base,3> vi, float3 bary : SV_DomainLocation) {
        appdata_base v;UNITY_INITIALIZE_OUTPUT(appdata_base,v);
        v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
        v.normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
        v.texcoord = vi[0].texcoord*bary.x + vi[1].texcoord*bary.y + vi[2].texcoord*bary.z;
        v2f o = vert (v);
        return o;
    }


    ENDCG

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        GrabPass{
            "_GrabTexture"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex tessvert_surf
            #pragma fragment frag
            #pragma hull hs_surf
            #pragma domain ds_surf
            #pragma target 5.0
            #pragma multi_compile_fog
            #pragma nodynlightmap nolightmap

            #include "UnityCG.cginc"

            ENDCG
        }
    }
}
