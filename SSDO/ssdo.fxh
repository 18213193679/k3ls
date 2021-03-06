texture2D AOWorkMap : RENDERCOLORTARGET <
	float2 ViewPortRatio = {1.0, 1.0};
	#if SSDO_COLOR_BLEEDING > 0
	string Format = "A16B16G16R16F";
	#else
	string Format = "R16F";
	#endif
>;
sampler AOWorkMapSampler = sampler_state {
    texture = <AOWorkMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

const float DepthLength = 10.0;	
static float InvDepthLength6 = 1.0 / pow(DepthLength, 6);
static float2 SSAORadiusB = (64.0 / 1024.0) / SSAORayCount * float2(1, ViewportSize.x/ViewportSize.y);

inline float GetOccRate(float2 Tex, float3 WPos, float3 N)
{
	float Depth = tex2D(sumDepthSamp,Tex).x;
	float3 RayPos = mul(coord2WorldViewPos(Tex,Depth),(float3x3)ViewInverse);
	const float SSAO_BIAS = 0.01;

	float3 v = RayPos - WPos;
	float distance2 = dot(v, v);
	float dotVN = max(dot(v, N) - SSAO_BIAS, 0.0f);
	float f = max(DepthLength * DepthLength - distance2, 0.0f);
	float f3 = f * f * f;
	float ao = (1 + 3 * aoPlus) * f3 * InvDepthLength6 * dotVN / (distance2 + 1e-3);

	return min(ao, 1.0);
}

float4 PS_AO( float2 Tex: TEXCOORD0 ) : COLOR
{
	float Depth = tex2D(sumDepthSamp,Tex).x;
	if(Depth<1+Epsilon)
		return float4(0,0,0,0);
	
	float3 N = tex2D(sumNormalSamp,Tex).xyz;
	float3 WPos = mul(coord2WorldViewPos(Tex,Depth),(float3x3)ViewInverse);

	float radMul = 1.0 / SSAORayCount * (3.14 * 2.0 * 7.0);
	float radAdd = hash12(Tex*Depth*ftime) * (PI * 2.0);

	float sum = 0.0;
	float3 col = 0;

	// MEMO: unrollするとレジスタを聞い�^ぎてコンパイルが宥らない
	// note: do not use global const variables in shader.
	#if SSDO_COLOR_BLEEDING > 0
	[loop]
	#else
	[unroll]
	#endif
	for(int j = 0; j < SSAORayCount; j++)
	{
		float2 sc;
		sincos(j * radMul + radAdd, sc.x, sc.y);
		float2 r = j * SSAORadiusB;
		float2 uv = sc * r + Tex;

		float ao = GetOccRate(uv, WPos, N);
		sum += ao;
		#if SSDO_COLOR_BLEEDING > 0
		float3 bouns = tex2D(AlbedoGbufferSamp,uv).xyz;
		float MINofBouns = min(min(bouns.x,bouns.y),bouns.z)*2;
		float MaxofPounds = max(max(bouns.x-MINofBouns,bouns.y-MINofBouns),bouns.z-MINofBouns);
		if(MaxofPounds>0)
		{
			bouns*=(1 + srgb2linear(tex2D(IBLDiffuseSampler, computeSphereCoord(tex2D(sumNormalSamp,uv).xyz)).xyz));
			col += min(0.3,ao) * bouns * invPi * LightAmbient;
		}
			
		#endif
	}

	// 圷のSAOのソ�`スでは、ddx/ddyでクアッド�g了の
	// �a屎を佩っていた。

	float s = saturate(1.0 - sum * (1.0 / SSAORayCount));
	return float4(s,col/ SSAORayCount);
}