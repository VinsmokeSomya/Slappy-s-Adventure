Shader "Simple Toon/Fiery Toon"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}

        [Header(Colorize)][Space(5)]  //colorize
        _Color("Color", COLOR) = (1,1,1,1)
        _DarkColor("Dark Color", COLOR) = (1,1,1,1)

        [HideInInspector] _ColIntense("Intensity", Range(0,3)) = 1
        [HideInInspector] _ColBright("Brightness", Range(-1,1)) = 0
        _AmbientCol("Ambient", Range(0,1)) = 0

        [Header(Detail)][Space(5)]  //detail
        [Toggle] _Segmented("Segmented", Float) = 1
        _Steps("Steps", Range(1,25)) = 3
        _StpSmooth("Smoothness", Range(0,1)) = 0
        _Offset("Lit Offset", Range(-1,1.1)) = 0

        [Header(Light)][Space(5)]  //light
        [Toggle] _Clipped("Clipped", Float) = 0
        _MinLight("Min Light", Range(0,1)) = 0
        _MaxLight("Max Light", Range(0,1)) = 1
        _Lumin("Luminocity", Range(0,2)) = 0

        [Header(Outline)][Space(5)]  //outline
        _OtlColor("Color", COLOR) = (0,0,0,1)
        _OtlWidth("Width", Range(0,10)) = 1

        [Header(Shine)][Space(5)]  //shine
        [HDR] _ShnColor("Color", COLOR) = (1,1,0,1)
        [Toggle] _ShnOverlap("Overlap", Float) = 0

        _ShnIntense("Intensity", Range(0,1)) = 0
        _ShnRange("Range", Range(0,1)) = 0.15
        _ShnSmooth("Smoothness", Range(0,1)) = 0

        [Header(Fire)][Space(5)]
        _FColor("Color", Color) = (0,0,0,1)
        _FTopColor("Top Color", Color) = (0,1,0,1)
        _FOtlWidth("Width", Range(0,20)) = 1
        _FAlpha("Alpha", Range(0,1)) = 1
        _FBaseColor("Base Color", Color) = (1,1,1,1)
        _FTimeScale("Time Scale", Float) = 1
    }

        SubShader
        {
            Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
            Pass
            {
                Name "DirectLight"
                LOD 300

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fwdbase

                #include "UnityCG.cginc"
                #include "UnityLightingCommon.cginc"
                #include "AutoLight.cginc"
                #include "STCore.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float3 normal : NORMAL;
                };

                struct v2f
                {
                    LIGHTING_COORDS(0,1)
                    float2 uv : TEXCOORD0;
                    float4 pos : SV_POSITION;
                    half3 worldNormal : NORMAL;
                    float3 viewDir : TEXCOORD2;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.viewDir = WorldSpaceViewDir(v.vertex);

                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    _MaxLight = max(_MinLight, _MaxLight);
                    _Steps = _Segmented ? _Steps : 1;
                    _StpSmooth = _Segmented ? _StpSmooth : 1;

                    //_DarkColor = fixed4(0,0,0,1);
                    _MaxAtten = 1.0;

                    float3 normal = normalize(i.worldNormal);
                    float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                    float3 view_dir = normalize(i.viewDir);
                    float3 halfVec = normalize(light_dir + view_dir);
                    float3 forward = mul((float3x3)unity_CameraToWorld, float3(0,0,1));

                    float NdotL = dot(normal, light_dir);
                    float NdotH = dot(normal, halfVec);
                    float VdotN = dot(view_dir, normal);
                    float FdotV = dot(forward, -view_dir);

                    fixed atten = SHADOW_ATTENUATION(i);
                    float toon = Toon(NdotL, atten);

                    fixed4 shadecol = _DarkColor;
                    fixed4 litcol = ColorBlend(_Color, _LightColor0, _AmbientCol);
                    fixed4 texcol = tex2D(_MainTex, i.uv) * litcol * _ColIntense + _ColBright;

                    float4 blendCol = ColorBlend(shadecol, texcol, toon);
                    float4 postCol = PostEffects(blendCol, toon, atten, NdotL, NdotH, VdotN, FdotV);

                    postCol.a = 1.;
                    return _LightColor0.a > 0 ? postCol : 0;
                }

                ENDCG
            }

            Tags { "RenderType" = "Opaque" "LightMode" = "ForwardAdd" }
            Pass
            {
                Name "SpotLight"
                BlendOp Max
                LOD 300

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fwdadd_fullshadows

                #include "UnityCG.cginc"
                #include "UnityLightingCommon.cginc"
                #include "AutoLight.cginc"
                #include "STCore.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float3 normal : NORMAL;
                };

                struct v2f
                {
                    LIGHTING_COORDS(0,1)
                    float2 uv : TEXCOORDSS;
                    float4 pos : SV_POSITION;
                    float3 worldPos : WORLD;
                    half3 worldNormal : NORMAL;
                    float3 viewDir : TEXCOORD2;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                    o.viewDir = WorldSpaceViewDir(v.vertex);

                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    _MaxLight = max(_MinLight, _MaxLight);
                    _Steps = _Segmented ? _Steps : 1;
                    _StpSmooth = _Segmented ? _StpSmooth : 1;

                    _MaxAtten = 1.0;

                    float3 normal = normalize(i.worldNormal);
                    float3 light_dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                    float3 view_dir = normalize(i.viewDir);
                    float3 halfVec = normalize(light_dir + view_dir);
                    float3 forward = mul((float3x3)unity_CameraToWorld, float3(0,0,1));

                    float NdotL = dot(normal, light_dir);
                    float NdotH = dot(normal, halfVec);
                    float VdotN = dot(view_dir, normal);
                    float FdotV = dot(forward, -view_dir);

                    float atten = LIGHT_ATTENUATION(i);
                    float toon = Toon(NdotL, atten);

                    fixed4 shadecol = _DarkColor;
                    fixed4 litcol = ColorBlend(_Color, _LightColor0, _AmbientCol);
                    fixed4 texcol = tex2D(_MainTex, i.uv) * litcol * _ColIntense + _ColBright;

                    float4 blendCol = ColorBlend(shadecol, texcol, toon);
                    float4 postCol = PostEffects(blendCol, toon, atten, NdotL, NdotH, VdotN, FdotV);

                    postCol.a = 1.;
                    return postCol;
                }

                ENDCG
            }

            UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

            //main
            Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
            Pass
            {
                Blend SrcAlpha One
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"

                fixed4 _FBaseColor;
                float _FAlpha;

                struct v2f {
                    float4 pos : SV_POSITION;
                    fixed4 color : COLOR;
                };

                v2f vert(appdata_base v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.color = _FBaseColor;

                    o.color.a *= (0.5 - 0.5 * v.normal.x) * _FAlpha;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target { return i.color; }
                ENDCG
            }

            //outline
            Pass
            {
                Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
                Blend SrcAlpha One
                //Cull Off
                //ZWrite Off

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                //#include "STCore.cginc"

                float _FOtlWidth, _FAlpha, _FTimeScale;
                fixed4 _FColor, _FTopColor;

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    fixed4 color : COLOR;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = v.vertex;
                    o.pos.xyz += normalize(v.normal.xyz) * _FOtlWidth * 0.008 * (1.1 + 0.1 * sin(_Time.w / _FTimeScale));
                    o.pos = UnityObjectToClipPos(o.pos);
                    float c = smoothstep(-1.0, 1.0, sin(3.141 * v.normal.x + _Time.w / _FTimeScale));
                    o.color = _FColor * (1.0 - c) + _FTopColor * c;
                    o.color.a *= (0.5 - 0.5 * v.normal.x) * _FAlpha;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    //clip(-negz(_OtlWidth));
                    return i.color;
                }

                ENDCG
            }
        }
}
