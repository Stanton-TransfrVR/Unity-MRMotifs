Shader "Interaction/RoundedBoxUnlitFade"
{
    Properties
    {
        _Color("Color", Color) = (0, 0, 0, 1)
        _BorderColor("BorderColor", Color) = (0, 0, 0, 1)
        _Dimensions("Dimensions", Vector) = (0, 0, 0, 0)
        _Radii("Radii", Vector) = (0, 0, 0, 0)
        _ZTest("ZTest", Float) = 4
        _ProximityStrength("Proximity Strength", Vector) = (0,0,0,0)
        _ProximityTransitionRange("Proximity Transition Range", Vector) = (0,1,0,0)
        _ProximityColor("Proximity Color", Color) = (0,0,0,1)
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        ZTest [_ZTest]
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            // Signed distance function for rounded boxes
            float sdRoundBox(float2 p, float2 b, float4 r)
            {
                r.xy = (p.x > 0.0) ? r.xy : r.zw;
                r.x  = (p.y > 0.0) ? r.x  : r.y;
                float2 q = abs(p) - b + r.x;
                return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
            }

            struct appdata
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
                fixed4 borderColor : TEXCOORD1;
                fixed4 dimensions : TEXCOORD2;
                fixed4 radii : TEXCOORD3;
                fixed3 positionWorld: TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _BorderColor)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _Dimensions)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _Radii)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximityColor)
                UNITY_DEFINE_INSTANCED_PROP(fixed2, _ProximityTransitionRange)
                UNITY_DEFINE_INSTANCED_PROP(fixed2, _ProximityStrength)
                UNITY_DEFINE_INSTANCED_PROP(int, _ProximitySphereCount)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere0)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere1)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere2)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere3)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere4)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere5)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere6)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere7)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere8)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _ProximitySphere9)
                UNITY_DEFINE_INSTANCED_PROP(float, _FadeAmount) // NEW FADE SUPPORT
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.radii = UNITY_ACCESS_INSTANCED_PROP(Props, _Radii);
                o.dimensions = UNITY_ACCESS_INSTANCED_PROP(Props, _Dimensions);
                o.borderColor = UNITY_ACCESS_INSTANCED_PROP(Props, _BorderColor);
                o.color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                o.positionWorld = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = (v.uv - float2(0.5, 0.5)) * 2.0 * o.dimensions.xy;

                return o;
            }

            float inverseLerp(float t, float a, float b)
            {
                return (t - a) / (b - a);
            }

            float getProximityMinDistance(float3 pos, int count, fixed4 spheres[10])
            {
                float minDist = 0.0;
                for (int i = 0; i < count; ++i)
                {
                    float3 spherePos = spheres[i].xyz;
                    float radius = spheres[i].w;
                    float dist = length(pos - spherePos) - radius;
                    dist = min(dist, 0.0);
                    minDist = min(minDist, dist);
                }
                return minDist;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                fixed4 proxSpheres[10] = {
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere0),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere1),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere2),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere3),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere4),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere5),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere6),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere7),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere8),
                    UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphere9),
                };

                int count = UNITY_ACCESS_INSTANCED_PROP(Props, _ProximitySphereCount);
                float2 transRange = UNITY_ACCESS_INSTANCED_PROP(Props, _ProximityTransitionRange);
                float2 strength = UNITY_ACCESS_INSTANCED_PROP(Props, _ProximityStrength);
                float4 proxColor = UNITY_ACCESS_INSTANCED_PROP(Props, _ProximityColor);
                float fade = UNITY_ACCESS_INSTANCED_PROP(Props, _FadeAmount);

                float proxDist = 0.0;
                if (count > 0)
                {
                    proxDist = abs(getProximityMinDistance(i.positionWorld, count, proxSpheres));
                }

                float dist = sdRoundBox(i.uv, i.dimensions.xy - i.dimensions.ww * 2.0, i.radii);
                float2 dd = float2(ddx(dist), ddy(dist));
                float ddLen = length(dd);

                float outer = i.dimensions.w;
                float inner = i.dimensions.z;

                float borderMask = (outer > 0.0 || inner > 0.0) ? 1.0 : 0.0;

                float outerDist = dist - outer * 2.0;
                float outerNorm = outerDist / ddLen;
                clip(1.0 - outerNorm < 0.1 ? -1 : 1);

                float innerDist = dist + inner * 2.0;
                float innerNorm = innerDist / ddLen;

                float4 border = i.borderColor;
                float4 innerCol = i.color;

                if (count > 0)
                {
                    float norm = saturate(inverseLerp(proxDist, transRange.x, transRange.y));
                    norm = sin((norm - 0.5) * 3.1415) * 0.5 + 0.5;
                    border = lerp(border, proxColor, norm * strength.x);
                    innerCol = lerp(innerCol, proxColor, norm * strength.y);
                }

                float t = saturate(innerNorm) * borderMask;
                float4 col = lerp(innerCol, border, t);
                col.a *= (1.0 - saturate(outerNorm));
                col.a *= fade; // FADE MULTIPLIER

                return col;
            }
            ENDCG
        }
    }
}
