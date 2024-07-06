Shader "Simple Toon/Lava Toon"
{
    Properties
    {
        _MainTex("Noise Texture", 2D) = "white" {}
        _NoiseScale("Noise Scale", Float) = 1
        _TimeScale("Time Scale", Float) = 1

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
        _FAlpha("Alpha", Range(0,1)) = 1
        _FBaseColor("Base Color", Color) = (1,1,1,1)

        _FNoiseScale("Fire Noise Scale", Float) = 1
        _FTimeScale("Fire Time Scale", Float) = 1

        _FThresh1("Threshold 1", Range(0, 1)) = 0.2
        _FThresh2("Threshold 2", Range(0, 1)) = 0.4
        _FThresh3("Threshold 3", Range(0, 1)) = 0.6
        _FThresh4("Threshold 4", Range(0, 1)) = 0.8

        [Header(Rim)][Space(5)]
        _RColor("Color", Color) = (0,0,0,1)
        _RIntensity("Intensity", Range(0, 2)) = 0.3
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

                float _NoiseScale, _TimeScale;

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
                    float3 wpos : TEXCOORD3;
                    half3 worldNormal : NORMAL;
                    float3 viewDir : TEXCOORD2;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    float4 worldScale = float4(
                        length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)), // scale x axis
                        length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)), // scale y axis
                        length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z)), 1.  // scale z axis
                        );
                    o.wpos = v.vertex * worldScale;
                    o.uv = v.uv;
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

                    _MaxAtten = 1.0;

                    float3 normal = normalize(i.worldNormal);
                    float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                    float3 view_dir = normalize(i.viewDir);
                    float3 halfVec = normalize(light_dir + view_dir);
                    float3 forward = mul((float3x3)unity_CameraToWorld, float3(0,0,1));

                    //float NdotL = dot(normal, light_dir);
                    float2 p = i.wpos.xy / _NoiseScale;
                    float2 p2 = i.wpos.yz / _NoiseScale;
                    float NdotL = (tex2D(_MainTex, p + float2(_Time.x, _Time.x) / _TimeScale).r + tex2D(_MainTex, p * 2. + float2(-_Time.x, _Time.x) / _TimeScale).r +
                        tex2D(_MainTex, p2 + float2(_Time.x, -_Time.x) / _TimeScale).r) - 1.2;
                    float NdotH = dot(normal, halfVec);
                    float VdotN = dot(view_dir, normal);
                    float FdotV = dot(forward, -view_dir);

                    fixed atten = 1.;
                    float toon = Toon(NdotL, atten);

                    fixed4 shadecol = _DarkColor;
                    fixed4 litcol = ColorBlend(_Color, _LightColor0, _AmbientCol);
                    fixed4 texcol = litcol * _ColIntense + _ColBright;

                    float4 blendCol = ColorBlend(shadecol, texcol, toon);
                    float4 postCol = PostEffects(blendCol, toon, atten, NdotL, NdotH, VdotN, FdotV);

                    postCol.a = 1.;
                    return _LightColor0.a > 0 ? postCol : 0;
                }

                ENDCG
            }

            //UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

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
                #include "STFunctions.cginc"

                float _FAlpha, _FNoiseScale, _FTimeScale, _FThresh1, _FThresh2, _FThresh3, _FThresh4;
                fixed4 _FColor, _FTopColor;
                sampler2D _MainTex;

                struct appdata
                {
                    float4 vertex : POSITION;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float4 wpos : TEXCOORD0;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    //o.wpos = mul(unity_ObjectToWorld, v.vertex);
                    float4 worldScale = float4(
                        length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)), // scale x axis
                        length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)), // scale y axis
                        length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z)), 1.  // scale z axis
                        );
                    o.wpos = v.vertex * worldScale;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float2 p = i.wpos.xy / _FNoiseScale;
                    float2 p2 = i.wpos.xz / _FNoiseScale;
                    float f = (tex2D(_MainTex, -p + float2(_Time.x, _Time.x) / _FTimeScale).r + tex2D(_MainTex, p * 3. + float2(-_Time.x, _Time.x) / _FTimeScale).r +
                        tex2D(_MainTex, p2 * 2.3 + float2(_Time.x, _Time.x) / _FTimeScale).r + tex2D(_MainTex, p2 * 1.1 + float2(_Time.x, -_Time.x) / _FTimeScale).r) * 0.75 - 1.2;

                    float a = step(_FThresh1, f);
                    float b = step(_FThresh2, f);
                    float c = step(_FThresh3, f);
                    float d = step(_FThresh4, f);
                    return ColorBlend(0., ColorBlend(_FColor, ColorBlend(_FTopColor, ColorBlend(_FColor, 0., d), c), b), a);
                }

                ENDCG
            }

            //rimlight
            Pass
            {
                Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
                Blend SrcAlpha One

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                #include "STFunctions.cginc"

                float _RIntensity;
                fixed4 _RColor;

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    half3 worldNormal : NORMAL;
                    float3 viewDir : TEXCOORD2;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.viewDir = WorldSpaceViewDir(v.vertex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float NdotV = 1. - dot(normalize(i.worldNormal), normalize(i.viewDir));
                    NdotV *= _RIntensity;
                    return float4(NdotV.rrr, 1.) * _RColor;
                }

                ENDCG
            }
        }
}
