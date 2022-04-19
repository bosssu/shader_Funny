Shader "Water/Votex"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        [Normal]_NormalTex ("Normal", 2D) = "white" {}
        _FoamTex("FoamTex",2D) = "white"{}
        _FoamStrengh("FoamStrengh",Range(0,1)) = 0.2
        _XSpeed("XSpeed",Range(0,1)) = 0.2
        _YSpeed("YSpeed",Range(0,1)) = 0.2
        _Gloss("Gloss",Range(0,0.2)) = 0.1
        _SpecStrengh("SpecStrengh",Range(0,0.2)) = 1
        _TessellateAmount("TessellateAmount",float) = 4

        _Votex_Para("Center",vector) = (0.5,0.5,0.2,0)  //x,y: vortex center z: vortex radius
        _Votex_depth("Votex Depth",Range(0,4)) = 0.1    //vortex depth
        _Votex_distortAmount("Votex_distortAmount",Range(0,20)) = 2 
        _Shape_distortAmount("Shape_distortAmount",Range(0,1)) = 0.5

    }

    CGINCLUDE
    
    #include "Assets/ShaderInclude/1UPUtility.cginc"
    #include "Assets/ShaderInclude/1UPMath.cginc"

    sampler2D _NormalTex,_FoamTex;
    float _XSpeed,_YSpeed,_Gloss,_SpecStrengh,_TessellateAmount,_FoamStrengh;
    fixed4 _BaseColor,_Votex_Para;
    float _Votex_depth,_Votex_distortAmount,_Shape_distortAmount;

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Sample fullforwardshadows tessellate:Tess vertex:VotexVert
        #pragma target 3.0

        float Tess(){
            return _TessellateAmount;
        }

        void VotexVert(inout appdata_base v){
            float3 center = float3(_Votex_Para.x,0,_Votex_Para.y);
            float radius = _Votex_Para.z;
            float dis = distance(v.vertex.xyz,center);
            float s = saturate((radius - dis)) / radius;
            float ss = s * s;
            //The closer you get to the center of the vortex, the greater the vertex offset. Ss = s* S, which creates an arc of vortices
            float offsetN = _Votex_depth * ss;
            
            //set the vertex's offset
            v.vertex.xyz = v.vertex.xyz - v.normal * offsetN;

            //distort(three steps：move the vortex's center to zero->rotate around y axis->move the vortex's center to oringin position)
            float3 tempVertex = v.vertex.xyz -center;
            tempVertex += ss * _Shape_distortAmount;
            tempVertex = mul(MATRIX_3_Y(ss * _Votex_distortAmount),tempVertex);
            v.vertex.xyz = tempVertex+center;

        }

        fixed4 LightingSample(inout SurfaceOutput o,half3 lightDir,half3 viewDir){
            return fixed4(o.Albedo,o.Alpha);
        }

        struct Input
        {
            float2 uv_NormalTex;
            float2 uv_FoamTex;
            float4 worldPosition;
            INTERNAL_DATA
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 mainColor = _BaseColor;

            float3 n1 = UnpackNormal(tex2D(_NormalTex,IN.uv_NormalTex + float2(_XSpeed,_YSpeed) * 0.1 * _Time.y));
            float3 n2 = UnpackNormal(tex2D(_NormalTex,IN.uv_NormalTex - float2(_XSpeed,_YSpeed) * 0.1 * _Time.y));
            float3 offset = BlendNormalRNM(n1,n2);

            half3 worldNormal = WorldNormalVector(IN,offset);

            //foam
            fixed4 foamColor = tex2D(_FoamTex,IN.uv_FoamTex);
            mainColor += foamColor * _FoamStrengh;

            //light
            half3 worldViewDir = normalize(WorldSpaceViewDir(IN.worldPosition));
            half3 worldLightDir = normalize(WorldSpaceLightDir(IN.worldPosition));
            half3 hvl = normalize(worldLightDir+worldViewDir);
            half3 specular = Highlights(IN.worldPosition.xyz,_Gloss,worldNormal,worldViewDir,worldLightDir);
            mainColor.rgb += specular * _SpecStrengh;

            o.Albedo = mainColor.rgb;
            o.Alpha = mainColor.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
