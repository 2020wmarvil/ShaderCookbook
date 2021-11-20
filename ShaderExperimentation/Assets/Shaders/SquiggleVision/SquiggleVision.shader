Shader "Unlit/SquiggleVision" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            VertOut vert (VertIn v) {
                VertOut o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(VertOut i) : SV_Target{
                float time = _Time.y;
                float timeInterval = 1;

                //float outTime = time - timeInterval * floor(time / timeInterval);

                float2 t = float2(sin(_Time.y * 5), sin(_Time.y*11));
                float2 displacement = (t + float2(1, 1)) * 0.5;
                fixed4 col = tex2D(_MainTex, i.uv.xy + displacement.xy);
                return col;
            }
            ENDCG
        }
    }
}
