Shader "Unlit/BlinnPhongShading" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Gloss ("Glossiness", Float) = 1
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

            sampler2D _MainTex;
            float _Gloss;
            float4 _MainTex_ST;

            float4 _AmbientColor;
            float _AmbientIntensity;
            float4 _DiffuseColor;
            float _DiffuseIntensity;
            float4 _SpecularColor;
            float _SpecularIntensity;

            float3 _LightPos;
            float4 _LightColor;

            VertOut vert (VertIn v) {
                VertOut o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag(VertOut i) : SV_Target{
                float3 N = normalize(i.normal);
                float3 L = _WorldSpaceLightPos0.xyz;

                float lambert = saturate(dot(N, L));
                float3 diffuseLight = lambert * _LightColor0.xyz;

                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 H = normalize(V + L);
                float3 specularLight = saturate(dot(H, N)) * (lambert > 0);

                specularLight = pow(specularLight, _Gloss); // specular exponent

                return float4(diffuseLight + specularLight, 1);
            }
            ENDCG
        }
    }
}
