/* TRANSPARENT FRESNEL EFFECT (with emission)
 * Recipe:
 * 0. Set Queue = Transparent, RenderType = Transparent, ZWrite Off, and Blend SrcAlpha OneMinusSrcAlpha
 * 1. Calculate world space position and normals
 * 2. Calculate camera dir as worldPos - worldCameraPos
 * 3. fresnel_strength = (dot(camDir, worldNormal) + 1.0)^power * scale + bias
 * 4. Use fresnel strength to lerp from base color to fresnel color
 * 5. Multiplicatively add emission color (optional)
 */ 

Shader "Unlit/FresnelTransparent" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Opacity ("Opacity", Range(0.0, 1.0)) = 1
        _EmissionMap ("Emission Texture", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0, 0, 0)
        _FresnelColor ("Fresnel Color", Color) = (1, 1, 1, 1)
        [PowerSlider(4)] _FresnelExponent ("Fresnel Exponent", Range(0.25, 4)) = 1
        _Bias ("Bias", float) = 0
        _Scale ("Scale", float) = 1
        _Power ("Power", float) = 1
    }

    SubShader {
        Tags {"Queue" = "Transparent" "RenderType"="Transparent" }
        LOD 100
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct VertIn {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct VertOut {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float R : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Opacity;

            sampler2D _EmissionMap;
            float4 _EmissionColor;

            float4 _FresnelColor;
            float _FresnelExponent;

            float _Bias;
            float _Scale;
            float _Power;

            VertOut vert (VertIn v) {
                VertOut o;
	            o.vertex = UnityObjectToClipPos(v.vertex);
	            o.uv = v.uv;

                float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal.xyz);

	            float3 I = normalize(posWorld - _WorldSpaceCameraPos.xyz);
	            o.R = _Bias + _Scale * pow(1.0 + dot(I, worldNormal), _Power);

	            return o;
            }

            fixed4 frag(VertOut i) : Color {
                float4 baseColor = tex2D(_MainTex, i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw);
                float4 colorResult = lerp(float4(baseColor.xyz, _Opacity), _FresnelColor, i.R);
                return colorResult * _EmissionColor;
            }
            ENDCG
        }
    }
}
