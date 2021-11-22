Shader "Unlit/SimpleWater" {
    Properties {
        _WaterColor ("Water Color", Color) = (0, 0, 0 , 0)
        [HDR] _RippleColor ("Ripple Color", Color) = (0, 0, 0 , 0)
        _CellDensity("Cell Density", float) = 1
        _ShearStrength("Shear Strength", float) = 1
        _RippleIntensity("Ripple Intensity", float) = 1
        _WaveScale("Wave Scale", float) = 1
        _WaveSpeed("Wave Speed", float) = 1
        _WaveSize("Wave Size", float) = 1

        _FoamIntensity("Foam Intensity", float) = 1
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
            };

            struct VertOut {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPosition : TEXCOORD1;
            };

            float4 _WaterColor;
            float4 _RippleColor;
            float _CellDensity;
            float _ShearStrength;
            float _RippleIntensity;
            float _WaveScale;
            float _WaveSpeed;
            float _WaveSize;
            float _FoamIntensity;

            sampler2D _CameraDepthTexture;

            inline float2 unity_voronoi_noise_randomVector (float2 UV, float offset) {
                float2x2 m = float2x2(15.27, 47.63, 99.41, 89.98);
                UV = frac(sin(mul(UV, m)) * 46839.32);
                return float2(sin(UV.y*+offset)*0.5+0.5, cos(UV.x*offset)*0.5+0.5);
            }
            
            void Unity_Voronoi_float(float2 UV, float AngleOffset, float CellDensity, out float Out, out float Cells) {
                float2 g = floor(UV * CellDensity);
                float2 f = frac(UV * CellDensity);
                float t = 8.0;
                float3 res = float3(8.0, 0.0, 0.0);
            
                for(int y=-1; y<=1; y++)
                {
                    for(int x=-1; x<=1; x++)
                    {
                        float2 lattice = float2(x,y);
                        float2 offset = unity_voronoi_noise_randomVector(lattice + g, AngleOffset);
                        float d = distance(lattice + offset, f);
                        if(d < res.x)
                        {
                            res = float3(d, offset.x, offset.y);
                            Out = res.x;
                            Cells = res.y;
                        }
                    }
                }
            }

            void Unity_RadialShear_float(float2 UV, float2 Center, float Strength, float2 Offset, out float2 Out) {
                float2 delta = UV - Center;
                float delta2 = dot(delta.xy, delta.xy);
                float2 delta_offset = delta2 * Strength;
                Out = UV + float2(delta.y, -delta.x) * delta_offset + Offset;
            }

            float2 unity_gradientNoise_dir(float2 p) {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }
            
            float unity_gradientNoise(float2 p) {
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(unity_gradientNoise_dir(ip), fp);
                float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
            }
            
            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out) {
                Out = unity_gradientNoise(UV * Scale) + 0.5;
            }

            VertOut vert (VertIn v) {
                VertOut o;

                float waveHeight;
                Unity_GradientNoise_float(v.uv + float2(_Time.y, _Time.y) * _WaveSpeed, _WaveScale, waveHeight);
                v.vertex.y += (waveHeight - 0.5) * _WaveSize;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;
                o.screenPosition = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag(VertOut i) : SV_Target{
                // apply a radial shear to our UVs
                float2 voronoiUV;
                Unity_RadialShear_float(i.uv, float2(0.5, 0.5), _ShearStrength, float2(0, 0), voronoiUV);

                // calculate voronoi value at this pixel
                float noise, cells;
                Unity_Voronoi_float(voronoiUV, _Time.y + 30, _CellDensity, noise, cells);

                // exponentiate the noise to get sharper lines
                noise = pow(noise, _RippleIntensity);

                // multiplicativley blend the ripple color
                float4 rippleColor = float4(noise, noise, noise, 1) * _RippleColor;
                
                // compute the screen depth at this point
                float2 textureCoordinate = i.screenPosition.xy / i.screenPosition.w;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, textureCoordinate);
                depth = LinearEyeDepth(depth);

                // subtract our vertex depth from the screen depth to get a mask which represents intersecting geometry
                float foamMask = depth - i.screenPosition.w;

                // invert and exponentiate to get crisp foam lines
                foamMask = 1 - foamMask;
                foamMask = pow(foamMask, _FoamIntensity);

                // additively blend
                return _WaterColor + rippleColor + foamMask;
            }
            ENDCG
        }
    }
}
