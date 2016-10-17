#include "common.fxsub"


float3 LightDirection : DIRECTION < string Object = "Light"; >;

static float4x4 matLightView = CreateLightViewMatrix(normalize(LightDirection));
static float4x4 matLightViewProject = mul(matLightView, matLightProject);
static float4x4 matLightProjectToCameraView = mul(matViewInverse, matLightView);
static float4x4 lightParam = CreateLightProjParameters(matLightProjectToCameraView);

texture DiffuseMap: MATERIALTEXTURE;
sampler DiffuseMapSamp = sampler_state {
	texture = <DiffuseMap>;
	MinFilter = POINT;	MagFilter = POINT;	MipFilter = POINT;
	ADDRESSU  = WRAP;	ADDRESSV  = WRAP;
};


shared texture PSSMDepth : OFFSCREENRENDERTARGET;
sampler PSSMsamp = sampler_state {
	texture = <PSSMDepth>;
	MinFilter = LINEAR;	MagFilter = LINEAR;	MipFilter = NONE;
	AddressU  = CLAMP;	AddressV = CLAMP;
};

struct DrawObject_OUTPUT
{
	float4 Pos	  : POSITION;
	float4 Tex	  : TEXCOORD0;
	float3 Normal	: TEXCOORD1;

	float4 LightPPos01	: TEXCOORD2;
	float4 LightPPos23	: TEXCOORD3;

	float4 PPos		: TEXCOORD4;
};

DrawObject_OUTPUT ShadowObjectVS(
	float4 Pos : POSITION, 
	float3 Normal : NORMAL, 
	float2 Tex : TEXCOORD0)
{
	DrawObject_OUTPUT Out = (DrawObject_OUTPUT)0;

	Out.PPos = Out.Pos = mul(Pos, matViewProject);
	Out.Normal = Normal;

	float4 PPos = mul(Pos, matLightViewProject);
	PPos.xy /= PPos.w;

	const float2 scale = float2(0.25, -0.25);
	Out.LightPPos01.xy = (PPos.xy * lightParam[0].xy + lightParam[0].zw);
	Out.LightPPos01.zw = (PPos.xy * lightParam[1].xy + lightParam[1].zw);
	Out.LightPPos23.xy = (PPos.xy * lightParam[2].xy + lightParam[2].zw);
	Out.LightPPos23.zw = (PPos.xy * lightParam[3].xy + lightParam[3].zw);
	Out.LightPPos01 *= scale.xyxy;
	Out.LightPPos23 *= scale.xyxy;

	Out.Tex = float4(Tex.xy, Out.Pos.z, PPos.z);

	return Out;
}

float4 ShadowObjectPS(DrawObject_OUTPUT IN, uniform bool useTexture) : COLOR
{
	float alpha = MaterialDiffuse.a;
	if (useTexture) alpha *= tex2D(DiffuseMapSamp, IN.Tex.xy).a;
	//clip(alpha - 0.01);

	float4 lightPPos0 = CalcCascadePPos(IN.LightPPos01.xy, float2(0, 0), 0);
	float4 lightPPos1 = CalcCascadePPos(IN.LightPPos01.zw, float2(1, 0), 1);
	float4 lightPPos2 = CalcCascadePPos(IN.LightPPos23.xy, float2(0, 1), 2);
	float4 lightPPos3 = CalcCascadePPos(IN.LightPPos23.zw, float2(1, 1), 3);

	float4 texCoord0 = lightPPos3;
	float4 texCoord1 = 0;
	if (lightPPos2.w > 0.0) { texCoord1 = texCoord0; texCoord0 = lightPPos2; }
	if (lightPPos1.w > 0.0) { texCoord1 = texCoord0; texCoord0 = lightPPos1; }
	if (lightPPos0.w > 0.0) { texCoord1 = texCoord0; texCoord0 = lightPPos0; }

	float casterDepth0 = tex2D(PSSMsamp, texCoord0.xy).x;
	float casterDepth1 = tex2D(PSSMsamp, texCoord1.xy).x;
	float casterDepth = lerp(lerp(1, casterDepth1, texCoord1.w), casterDepth0, texCoord0.w);
	float receiverDepth = IN.Tex.w;

	float depthSlope = ShadowSlopeScaledBias(receiverDepth);
	float depthBias = (IN.PPos.z / LightZMax + depthSlope) * 0.005;
	receiverDepth -= depthBias;

	float s = 1.5 / SHADOW_MAP_SIZE;	
	float sdrate = 30000.0 / 4.0 - 0.05;

	float shadow = 0;
	shadow += CalcLight(casterDepth, receiverDepth, sdrate);
	shadow += CalcLight(tex2D(PSSMsamp, texCoord0.xy + float2( s, s)).x, receiverDepth, sdrate);
	shadow += CalcLight(tex2D(PSSMsamp, texCoord0.xy + float2(-s, s)).x, receiverDepth, sdrate);
	shadow += CalcLight(tex2D(PSSMsamp, texCoord0.xy + float2( s,-s)).x, receiverDepth, sdrate);
	shadow += CalcLight(tex2D(PSSMsamp, texCoord0.xy + float2(-s,-s)).x, receiverDepth, sdrate);
	shadow += CalcLight(tex2D(PSSMsamp, texCoord0.xy + float2( s, 0)).x, receiverDepth, sdrate);
	shadow += CalcLight(tex2D(PSSMsamp, texCoord0.xy + float2(-s, 0)).x, receiverDepth, sdrate);
	shadow += CalcLight(tex2D(PSSMsamp, texCoord0.xy + float2( 0, s)).x, receiverDepth, sdrate);
	shadow += CalcLight(tex2D(PSSMsamp, texCoord0.xy + float2( 0,-s)).x, receiverDepth, sdrate);
	shadow /= 9;
	


	shadow = lerp(1,shadow,min(0,alpha - RecieverAlphaThreshold)/(1 - RecieverAlphaThreshold));
	
	shadow = min(shadow, saturate(dot(normalize(IN.Normal), -LightDirection)));
	return float4(shadow, IN.PPos.z, 0, 1);
}


#define OBJECT_TEC(name, mmdpass, tex) \
	technique name < string MMDPass = mmdpass; bool UseTexture = tex; \
	>{ \
		pass DrawObject { \
			AlphaTestEnable = false; AlphaBlendEnable = false; \
			VertexShader = compile vs_3_0 ShadowObjectVS(); \
			PixelShader  = compile ps_3_0 ShadowObjectPS(tex); \
		} \
	}
	

OBJECT_TEC(MainTecBS2, "object_ss", false)
OBJECT_TEC(MainTecBS3, "object_ss", true)

technique EdgeTec < string MMDPass = "edge"; > {}
technique ShadowTec < string MMDPass = "shadow"; > {}
technique ZplotTec < string MMDPass = "zplot"; > {}