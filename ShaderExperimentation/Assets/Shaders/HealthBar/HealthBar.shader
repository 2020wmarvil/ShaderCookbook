Shader "Unlit/HealthBar" {
    Properties {
        _HealthTexture ("Health Texture", 2D) = "white" {}
        _Health("Health", Range(0, 1)) = 1
        _MaxThreshold("Max", Range(0, 1)) = 0.8
        _MinThreshold("Min", Range(0, 1)) = 0.2
        _Color1("Main Color", Color) = (1, 1, 1, 1)
        _Color2("Secondary Color", Color) = (1, 1, 1, 1)
        _BackgroundColor("Background Color", Color) = (1, 1, 1, 1)
        _UseTex ("Use Texture", Range(0, 1)) = 1
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _HealthTexture;
            float _Health;
            float _MaxThreshold;
            float _MinThreshold;
            float4 _Color1;
            float4 _Color2;
            float4 _BackgroundColor;
            float _UseTex;

            float InverseLerp(float a, float b, float v) {
                return (v - a) / (b - a);
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                float2 coords = i.uv;
                coords.x *= 8;

                float2 nearestPoint = float2(clamp(coords.x, 0.5, 7.5), 0.5);
                float sdf = distance(coords, nearestPoint) * 2 - 1;

                clip(-sdf);

                float borderSdf = sdf + 0.1;

                float pd = fwidth(borderSdf); // screen space partial derivative for anti aliasing
                float borderMask = 1 - saturate(borderSdf / pd);

                float tHealthColor = saturate(InverseLerp(_MinThreshold, _MaxThreshold, _Health)); // maps our input T value to interpolate between min and max

                float4 healthColor = lerp(_Color1, _Color2, 1 - tHealthColor);
                float healthMask = _Health > i.uv.x;

                if (1 - healthMask) discard; // doesn't render the current pixel. transparency without sorting issues!!!

                float4 color = healthColor * healthMask + _BackgroundColor * (1 - healthMask);

                float4 texColor = tex2D(_HealthTexture, float2(_Health, i.uv.y));

                float flash = cos(_Time.y * 4) * 0.4 + 1;

                if (_Health < _MinThreshold)
                    return (color * (1 - _UseTex) + texColor * _UseTex) * borderMask * flash;
                return color * (1 - _UseTex) + texColor * _UseTex * borderMask;
            }
            ENDCG
        }
    }
}
