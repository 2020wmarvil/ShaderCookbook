Shader "Hidden/ScreenTransitionImageEffect" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {
        Cull Off ZWrite Off ZTest Always

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

            VertOut vert (VertIn v) {
                VertOut o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            float4 boxBlur(sampler2D tex, float2 uv, float4 size) {
                float4 c = tex2D(tex, uv + float2(-size.x, -size.y))
                         + tex2D(tex, uv + float2(-size.x, 0))
                         + tex2D(tex, uv + float2(-size.x, size.y))
                         + tex2D(tex, uv + float2(0, -size.y))
                         + tex2D(tex, uv + float2(0, 0))
                         + tex2D(tex, uv + float2(0, size.y))
                         + tex2D(tex, uv + float2(size.x, -size.y))
                         + tex2D(tex, uv + float2(size.x, 0))
                         + tex2D(tex, uv + float2(size.x, size.y));

                return c / 9;
            }

            fixed4 frag(VertOut i) : SV_Target{
                fixed4 col = boxBlur(_MainTex, i.uv, _MainTex_TexelSize);
                return col;
            }
            ENDCG
        }
    }
}
