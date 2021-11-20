Shader "Unlit/WaveyEffect" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise", 2D) = "white" {}

        _DistortionDamper("Distortion Damper", Range(0, 15)) = 10
        _DistortionSpreader("Distortion Spreader", float) = 100
        _TimeDamper("Time Damper", Range(0, 45)) = 30
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct VertIn {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VertOut {
                float2 uv : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NoiseTex;
            float _DistortionDamper;
            float _DistortionSpreader;
            float _TimeDamper;

            VertOut vert (VertIn v) {
                VertOut o;
                o.worldPosition = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(VertOut i) : SV_Target{
                float2 offset = float2(
                    tex2D(_NoiseTex, float2(i.worldPosition.y / _DistortionSpreader, _Time.z / _TimeDamper)).r,
                    tex2D(_NoiseTex, float2(_Time.z / _TimeDamper, i.worldPosition.x / _DistortionSpreader)).r
                    );

                fixed4 col = tex2D(_MainTex, i.uv + offset / _DistortionDamper);
                return col;
            }
            ENDCG
        }
    }
}
