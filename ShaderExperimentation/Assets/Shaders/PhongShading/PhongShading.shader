Shader "Unlit/PhongShading" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Surface Color", Color) = (1, 1, 1, 1)
        _Gloss ("Glossiness", Range(0, 1)) = 1
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct VertIn {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct VertOut {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
            };

            float4 _Color;
            float _Gloss;

            VertOut vert (VertIn v) {
                VertOut o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag(VertOut i) : SV_Target{
                float3 N = normalize(i.normal);
                float3 L = _WorldSpaceLightPos0.xyz;

                float3 diffuseLight = saturate(dot(N, L)) * _LightColor0.rgb;

                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 R = reflect(-L, N); // reflect Light across Normal
                float3 specularLight = saturate(dot(V, R));

                float specularExponent = exp2(_Gloss * 6 + 1); // magic numbers from Freya Holmer
                specularLight = pow(specularLight, specularExponent); 
                specularLight *= _LightColor0.xyz;

                return float4(_Color * diffuseLight + specularLight, 1);
            }
            ENDCG
        }
    }
}
